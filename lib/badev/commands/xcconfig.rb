require 'xcodeproj'

module Badev
  module XCConfig

    extend Badev::Helpers

    XCPROJECT = File.join(TOOLS_DIR, "xcproject")

    def self.prefix_header_path(target, root_dir, conf="Debug")
      return nil if target.nil? or root_dir.nil?
      original_pch = `#{XCPROJECT} print-settings -e -p #{shellescape(target.project.path)} -t #{shellescape(target.name)} -c #{shellescape(conf)} GCC_PREFIX_HEADER`.strip
      original = Pathname.new(original_pch)
      if original.absolute?
        unless original_pch =~ /^#{root_dir}/
          return nil
        end
      end

      original
    end

    def self.generated_prefix_header_path(target, root_dir, conf="Debug")
      return nil if target.nil?
      # get the originally specified precompiled header
      original = prefix_header_path(target, root_dir, conf)

      # sanity check
      return nil if original.nil? or original.to_s.empty?

      # bail if original value is our generated pch
      return original if original.to_s =~ /_generated.pch$/

      # generated value based on original pch
      original.dirname + "#{original.basename(original.extname)}_generated.pch"
    end

    def self.collect_xcodeprojs(dirs)
      xcodeprojs = []

      dirs.each do |base|
        if File.exists? base then
          Dir.glob(File.join(base, "**/*.xcodeproj")) do |dir|
            xcodeprojs << File.expand_path(dir)
          end
        end
      end

      xcodeprojs
    end

    def self.make_xcconfig_line(key, value)
      v = value
      if value.kind_of?(Array) then
        v = value.join(" ")
      end

      "#{key} = #{v}"
    end

    def self.build_default_xcconfig(destname, project, configuration, target, settings_list)
      template = <<-XEND.gsub(/^ {6}/, '')
      //!bagen generate binaryage #{shellescape(project)} #{shellescape(configuration)} #{shellescape(target)}
      //
      // this file should be set as #{configuration} configuration for target #{target} in #{project}.xcodeproj

      // following included file can be regenerated by running 'badev regen_xcconfigs'
      #include "#{destname}"

      // here you can follow with your custom settings overrides if needed
      XEND

      export = ""
      settings_list.each do |settings|
        export += "\n"
        settings.each do |key, value|
          export += "// " + make_xcconfig_line(key, value) + "\n"
        end
      end

      template + export
    end

    def self.generated_xcconfig_path(xcconfig)
      return "" if xcconfig.nil?
      xcconfig = Pathname.new(xcconfig)
      return xcconfig if xcconfig.to_s =~ /_generated\.xcconfig$/
      xcconfig.dirname.join("#{xcconfig.basename(xcconfig.extname)}_generated.xcconfig").to_s
    end

    def self.init_configs_for_proj(proj, dest)
      basename = File.basename proj.path, ".xcodeproj"

      # create xcconfig file for each configuration-target combination
      proj.build_configurations.each do |conf|
        configuration_settings = conf.build_settings

        proj.targets.each do |target|
          target_settings = target.build_settings(conf.name)

          # TODO: here we should sanitize filenames for bad characters
          filename = File.join(dest, "#{basename}_#{conf.name}_#{target.name}.xcconfig")
          destname = (File.basename filename, ".xcconfig") + "_generated.xcconfig"
          unless File.exists? filename
            content = build_default_xcconfig(destname, basename, conf.name, target.name, [configuration_settings, target_settings])
            File.open(filename, 'w') { |file| file.write(content) }
            relpath = "./"+Pathname.new(filename).relative_path_from(Pathname.new(Dir.pwd)).to_s
            puts "generated: #{relpath.yellow}"
          else
            puts "#{filename.blue} already exists => skipping"
          end
        end
      end
    end

    def self.convert_generator(path)
      lines = File.read(path).split("\n")
      return unless lines[0] =~ /\/\/!/
      i = lines[0].rindex('>')
      return unless i
      lines[0] = lines[0].slice(0,i).rstrip
      content = lines.join("\n")
      File.open(path, "w") { |file| file.write(content) }
    end

    def self.parse_xcconfig_header(path)
      # convert previous generator that redirected stdout
      #   the new generator has an option for specifing output file separatly from the args passed to it
      convert_generator(path)
      lines = File.read(path).split("\n")
      return unless lines[0] =~ /\/\/!(.*)/
      generator = $1.strip
    end

    def self.init_configs_in_tree(root_path)
      xcodeprojs = collect_xcodeprojs([root_path])

      xcodeprojs.each do |xcodeproj|
        xcconfig_dir = xcodeproj.gsub(".xcodeproj", ".xcconfigs")
        proj = Xcodeproj::Project.open(xcodeproj)
        FileUtils.mkdir_p xcconfig_dir
        init_configs_for_proj(proj, xcconfig_dir)
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
            puts "in #{dir.blue}:" if lastdir!=dir
            lastdir = dir
            generator << " --root #{shellescape(root_path)} --project_dir #{shellescape(proj.path.dirname.to_s)}"
            generator << " --output #{shellescape(generated_xcconfig_path(xcconfig))} --pch #{shellescape(generated_prefix_header_path(target, root_path, conf.name))}"
            sys(generator)
          end
        end
      end
    end

  end
end
