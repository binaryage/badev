# frozen_string_literal: true

require 'xcodeproj'

module Badev
  module XCConfig
    extend Badev::Helpers

    XCPROJECT = File.join(TOOLS_DIR, 'xcproject')

    def self.prefix_header_path(target, root_dir, conf = 'Debug')
      return nil if target.nil? || root_dir.nil?

      arg_p = shellescape(target.project.path)
      arg_t = shellescape(target.name)
      arg_c = shellescape(conf)
      original_pch = `#{XCPROJECT} print-settings -e -p #{arg_p} -t #{arg_t} -c #{arg_c} GCC_PREFIX_HEADER`.strip
      original = Pathname.new(original_pch)
      return nil if original.absolute? && !original_pch.match?(/^#{root_dir}/)

      original
    end

    def self.generated_prefix_header_path(target, root_dir, conf = 'Debug')
      return nil if target.nil?

      # get the originally specified precompiled header
      original = prefix_header_path(target, root_dir, conf)

      # sanity check
      return nil if original.nil? || original.to_s.empty?

      # bail if original value is our generated pch
      return original if original.to_s.match?(/_generated.pch$/)

      # generated value based on original pch
      original.dirname + "#{original.basename(original.extname)}_generated.pch"
    end

    def self.collect_xcodeprojs(dirs)
      xcodeprojs = []

      dirs.each do |base|
        next unless File.exist? base

        Dir.glob(File.join(base, '**/*.xcodeproj')) do |dir|
          xcodeprojs << File.expand_path(dir)
        end
      end

      xcodeprojs
    end

    def self.make_xcconfig_line(key, value)
      v = value
      v = value.join(' ') if value.is_a?(Array)

      "#{key} = #{v}"
    end

    def self.build_default_xcconfig(destname, project, configuration, target, settings_list, original_xcconfig)
      template = <<~XCCONFIG_HEADER
        //!bagen generate binaryage #{shellescape(project)} #{shellescape(configuration)} #{shellescape(target)}
        //
        // this file should be set as #{configuration} configuration for target #{target} in #{project}.xcodeproj
      XCCONFIG_HEADER

      unless original_xcconfig.empty?
        template += <<-XCCONFIG_HEADER

          // include the previously set xcconfig
          #include "#{original_xcconfig}"
        XCCONFIG_HEADER
      end

      template += <<~XCCONFIG_HEADER

        // following included file can be regenerated by running 'badev regen_xcconfigs'
        #include "#{destname}"

        // here you can follow with your custom settings overrides if needed
      XCCONFIG_HEADER

      export = ''
      settings_list.each do |settings|
        export += "\n"
        settings.each do |key, value|
          export += "// #{make_xcconfig_line(key, value)}\n"
        end
      end

      template + export
    end

    def self.generated_xcconfig_path(xcconfig)
      return '' if xcconfig.nil?

      xcconfig = Pathname.new(xcconfig)
      return xcconfig if xcconfig.to_s.match?(/_generated\.xcconfig$/)

      xcconfig.dirname.join("#{xcconfig.basename(xcconfig.extname)}_generated.xcconfig").to_s
    end

    def self.original_xcconfig_path(target, configuration)
      arg_p = shellescape(target.project.path)
      arg_t = shellescape(target.name)
      arg_c = shellescape(configuration.name)
      `#{XCPROJECT} list -x -p #{arg_p} -t #{arg_t} -c #{arg_c}`.strip
    end

    def self.original_xcconfig_include_path(current, xcconfig)
      return '' if current.empty? || (xcconfig == current)

      Pathname.new(current).relative_path_from(Pathname.new(xcconfig).dirname).to_s
    end

    def self.init_configs_for_proj(proj, dest, options)
      basename = File.basename proj.path, '.xcodeproj'

      # create xcconfig file for each configuration-target combination
      proj.build_configurations.each do |conf|
        configuration_settings = conf.build_settings

        proj.targets.each do |target|
          begin
            next unless target.product_reference # this skips external and aggregate targets
          rescue
            # undefined method `product_reference' for
            # #<Xcodeproj::Project::Object::PBXLegacyTarget:0x007fe1d9490f58> (NoMethodError)
            next
          end
          target_settings = target.build_settings(conf.name)

          # TODO: here we should sanitize filenames for bad characters
          filename = File.join(dest, "#{basename}_#{conf.name}_#{target.name}.xcconfig")
          destname = "#{File.basename filename, '.xcconfig'}_generated.xcconfig"
          original_xcconfig = original_xcconfig_path(target, conf)
          if File.exist? filename
            puts "#{filename.blue} already exists => skipping"
          else
            settings = [configuration_settings, target_settings]
            xcconfig = original_xcconfig_include_path(original_xcconfig, filename)
            configuration = conf.name
            content = build_default_xcconfig(destname, basename, configuration, target.name, settings, xcconfig)
            File.open(filename, 'w') { |file| file.write(content) }
            relpath = "./#{Pathname.new(filename).relative_path_from(Pathname.pwd)}"
            puts "generated: #{relpath.yellow}"
          end

          next unless options.add && File.exist?(filename)
          next if original_xcconfig == filename

          arg_t = shellescape(target.name)
          arg_c = shellescape(conf.name)
          arg_g = shellescape(options.group)
          arg_file = shellescape(filename)
          sys("#{XCPROJECT} set-config -a -f -p #{shellescape(proj.path)} -t #{arg_t} -c #{arg_c} -g #{arg_g} #{arg_file}")
        end
      end
    end

    def self.convert_generator(path)
      lines = File.read(path).split("\n")
      return unless lines[0].match?(/\/\/!/)

      i = lines[0].rindex('>')
      return unless i

      lines[0] = lines[0].slice(0, i).rstrip
      content = lines.join("\n")
      File.open(path, 'w') { |file| file.write(content) }
    end

    def self.parse_xcconfig_header(path)
      # convert previous generator that redirected stdout
      #   the new generator has an option for specifing output file separatly from the args passed to it
      convert_generator(path)
      lines = File.read(path).split("\n")
      return unless lines[0] =~ /\/\/!(.*)/

      Regexp.last_match(1).strip
    end

    def self.init_configs_in_tree(_args, options)
      xcodeprojs = collect_xcodeprojs([options.root])

      xcodeprojs.each do |xcodeproj|
        xcconfig_dir = xcodeproj.gsub('.xcodeproj', '.xcconfigs')
        proj = Xcodeproj::Project.open(xcodeproj)
        FileUtils.mkdir_p xcconfig_dir
        init_configs_for_proj(proj, xcconfig_dir, options)
      end
    end

    def self.regen_configs_in_tree(root_path)
      lastdir = nil

      xcodeprojs = collect_xcodeprojs([root_path])
      xcodeprojs.each do |xcodeproj|
        proj = Xcodeproj::Project.open(xcodeproj)
        proj.targets.each do |target|
          target.build_configurations.each do |conf|
            next unless conf.base_configuration_reference

            xcconfig = conf.base_configuration_reference.real_path

            generator = parse_xcconfig_header(xcconfig.to_s)
            next unless generator

            dir = xcconfig.dirname.to_s
            puts "in #{dir.blue}:" if lastdir != dir
            lastdir = dir
            generator << " --root #{shellescape(root_path)} --project_dir #{shellescape(proj.path.dirname.to_s)}"
            generator << " --output #{shellescape(generated_xcconfig_path(xcconfig))}"
            sys(generator)
          end
        end
      end
    end
  end
end
