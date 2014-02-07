require 'baproj'

module Badev
  module ClassPrefixer
    
    class ClassPrefixHeaderContext
      include Badev::Helpers
      
      def initialize(classes, args, options)
        @project = Baproj::Project.open(options.root)
        @classes = classes
        @args = args
      end
      
      def include(template_path)
        return unless File.exist? template_path
        template = ERB.new File.read(template_path)
        Dir.chdir File.dirname(template_path) do
          template.result(get_binding)
        end
      end
      
      def get_binding # this is only a helper method to access the objects binding method
        binding
      end
    end
    
    extend Badev::Helpers
    
    def self.templates_dir
      Pathname.new(__FILE__).realpath.join("../../../../templates/prefixing").expand_path
    end
    
    def self.generate_header(template, classes, args, options)
      template_path = File.join(templates_dir(), template + ".h.erb")
      die("required template does not exists at #{template_path.yellow}") unless File.exists? template_path
    
      result = nil
      context = ClassPrefixHeaderContext.new(classes, args, options)
      template = ERB.new File.read(template_path)
      Dir.chdir File.dirname(template_path) do
        result = template.result(context.get_binding)
      end
    
      # final cleanup
      lines = result.split("\n")
      lines.map! { |line| line.strip } # strip lines
      lines.join("\n")
    end
    
    def self.generate_pch(pch, original_pch=nil)
      # TODO: change include path and have simple import statement or have relative path in import statement
      header = <<-XEND.gsub(/^ {6}/, '')
      //
      // #{pch.basename}
      //

      XEND
    
      lines = header.split("\n")
    
      lines << "#import \"#{original_pch.relative_path_from(pch.dirname)}\"" unless original_pch.nil?
      lines << "#import <ClassPrefix/PrefixedClassAliases.h>"
    
      lines.join("\n")
    end
    
    def self.build_regexp_from_classes(classes)
      subexprs = []
      classes.each do |item|
        next unless item
        re = Regexp.new(item)
        subexprs << re
      end
      Regexp.union(subexprs)
    end
    
    def self.collect_classes(files, wrapped=false)
      classes = []
      
      files.each do |file|
        next unless file =~ /\.(pch|h|mm|m|hpp)$/
        original = File.read(file)
        if wrapped then
          original.scan(/(BA_PREFIXED_CLASS\()(\w+)/) do |wrap,cls|
            classes << cls
          end
        else
          original.scan(/^([^\/].*)?(@implementation\s+)((?<!BA_PREFIXED_CLASS\()\w+)(\s+(?!\())/) do |pre,imp,cls,post|
            classes << cls
          end
        end
      end

      # reverse order is important for same-prefix identifiers to work
      # if TotalFinder and TotalFinderPlugin are both in the list, we want TotalFinderPlugin to go first
      # this is a limitation of how Regexp.union works, it gives us only first match from united regexp
      classes.compact.sort.uniq.reverse
    end
    
    def self.collect_target_files(_dir)
      files = []
      dirs = Array(_dir)
      dirs.each do |dir|
        next dir unless File.directory?(dir)
        Dir.chdir(dir) do
          Dir.glob("**/*") do |file|
            next if file =~ /(BaClassPrefix|PrefixedClassAliases)\.h/
            next unless file =~ /(\.(pch|h|mm|m|hpp|xib|sdef)|.*Info.plist)$/
            full = File.join(dir, file)
            files << full
          end
        end
      end
      files
    end
    
    def self.handle_arbitrary_cases(original, modified, regexp, classes, baproj)

      # # BaClassPrefix.h resolves this problem by defining NSClassFromString macro that calls a custom function
      # #
      # # handle NSClassFromString(@"something") cases
      # original.gsub!(/(NSClassFromString\s*\(\s*@\s*")(\w+_)?(#{regexp})(")/) do |m|
      #  next m if $2 =~ /#{baproj.prefix}/
      #  next m unless classes.include? $3
      #  modified = true
      #  "#{$1}#{baproj.prefix}_#{$3}#{$4}"
      # end

      # className] isEqualToString:@"..."
      original.gsub!(/(className\s*\]\s*isEqualToString:\s*@)"(\w+_)?(#{regexp})"/) do |m|
        next m if $2 =~ /#{baproj.prefix}/
        next m unless classes.include? $3
        modified = true
        "#{$1}BA_PREFIXED_CLASS_STR(#{$3})"
      end
      
      # NSStringFromClass(...) isEqualToString:@"..."
      original.gsub!(/(NSStringFromClass\(.+?\)\s*isEqualToString:\s*@)"(\w+_)?(#{regexp})"/) do |m|
        next m if $2 =~ /#{baproj.prefix}/
        next m unless classes.include? $3
        modified = true
        "#{$1}BA_PREFIXED_CLASS_STR(#{$3})"
      end
  
      # handle XIB cases:
      # <customObject id="98" customClass="GTMUILocalizer">
      # <class className="GTMUILocalizer" superclassName="NSObject">
      original.gsub!(/(className|customClass)(=")(\w+_)?(#{regexp})(")/) do |m|
        next m if $3 =~ /#{baproj.prefix}/
        next m unless classes.include? $4
        modified = true
        "#{$1}#{$2}#{baproj.prefix}_#{$4}#{$5}"
      end
  
=begin
      # This takes significantly longer than XIB method above (using plist gem, haven't tested with JSON yet)
      #
      # The method below uses ibtool to extract and change class names within an xib
      #   and needs a file path to function correctly
      #  NOTE: needs ``require 'json'``
      #
      # export classes from xib
      # each matched class from xib -> rename class with prefix in xib
      ibtool = `xcrun --find ibtool`.strip
      old_classes = `#{ibtool} --classes #{file} | plutil -convert json -o - -`
      return unless old_classes
  
      xib_classes = JSON.parse(old_classes)['com.apple.ibtool.document.classes']
      xib_classes.each do |k,v|
        next unless v
        klass = v['class']
        next if klass.start_with?("NS")
        next if klass.start_with?("#{baproj.prefix}_")
        new_klass = ""
        klass.match(/^(\w+_)?(#{regexp})$/) do |m|
          new_klass = baproj.prefix + "_" + m[2]
        end
        next unless new_klass.length > 0
        `#{ibtool} --convert #{klass}-#{new_klass} #{file}`
      end
=end
  
      # handle Info.plist:
      # <string>VisorPlugin</string>
      # check that we are not modifing an Info.plist with already expanded build settings as bundle and class names can easily overlap
      original.gsub!(/(<string>)(\w+_)?(#{regexp})(<\/string>)/) do |m|
        next m if $2 =~ /#{baproj.prefix}/
        next m unless classes.include? $3
        modified = true
        "#{$1}#{baproj.prefix}_#{$3}#{$4}"
      end
  
      # handle sdef
      # <cocoa class="NSApplication">
      original.gsub!(/(cocoa\s+class=")(\w+_)?(#{regexp})(")/) do |m|
        next m if $2 =~ /#{baproj.prefix}/
        next m unless classes.include? $3
        modified = true
        "#{$1}#{baproj.prefix}_#{$3}#{$4}"
      end

      # # TODO: Determine if we can use aliased class or if actual class is required
      # original.gsub!("DECLARE_CHECKED_OBJC_PTR(#{baproj.prefix}") do |m|
      #  modified = true
      #  "DECLARE_CHECKED_OBJC_PTR_MANGLED("
      # end

      return modified
    end
    
    def self.fix_classes_in_files(files, classes, all_class_tokens, baproj)
      regexp = build_regexp_from_classes(classes).to_s
  
      files.each do |file|
        original = File.read(file)
        modified = false
        
        if all_class_tokens
          original.gsub!(/(@class\s+.*)((?<!BA_PREFIXED_CLASS\()#{regexp})(.*;)/) do |m|
            modified = true
            "#{m}".gsub(/[\s,](#{regexp})[\s,;]/) do |n|
              "BA_PREFIXED_CLASS(#{$1})"
            end
          end
          
          modified = handle_arbitrary_cases(original, modified, regexp, classes, baproj)
          
        else
          original.gsub!(/(@interface\s+)(#{regexp})(\s+:)/) do |m|
            modified = true
            "#{$1}BA_PREFIXED_CLASS(#{$2})#{$3}"
          end
          
          original.gsub!(/(@implementation\s+)(#{regexp})((?!\()\s*)/) do |m|
            modified = true
            "#{$1}BA_PREFIXED_CLASS(#{$2})#{$3}"
          end
        end
        
        next unless modified
        
        File.open(file, "w") { |f| f.write(original) }
      end
    end
    
    def self.fix_class_names(files, baproj)
      classes = collect_classes(files, false)
      fix_classes_in_files(files, classes, false, baproj) unless classes.empty?
      classes = collect_classes(files, true)
      fix_classes_in_files(files, classes, true, baproj) unless classes.empty?
    end
    
    def self.prefix_classes(root_dir)
      files = collect_target_files(root_dir)
      fix_class_names(files, Baproj::Project.open(root_dir))
    end
    
    def self.init_pch_for_proj(proj, force=false)
      proj_dir = proj.path.dirname
      finished_targets = []
      
      # Generate precompiled header for each target
      proj.targets.each do |target|
        target.build_configurations.each do |conf|
          original = proj_dir + Badev::XCConfig.prefix_header_path(target, conf.name)
          generated = Badev::XCConfig.generated_prefix_header_path(target, conf.name)
          next if generated.nil? or generated.to_s.empty?
        
          pch_file = proj_dir + generated
        
          if pch_file.exist?
            unless force
              puts "#{pch_file.to_s.blue} already exists => skipping"
              next
            end
            next if finished_targets.inlude? target.name
          end
        
          unless pch_file.dirname.exist?
            puts "Failed to generate prefix header (#{pch_file.basename}) => #{pch_file.dirname} doesn't exist".red
            next
          end
        
          content = generate_pch(pch_file, original)
          File.open(pch_file, 'w') { |file| file.write(content) }
          
          finished_targets << target.name
        end
      end
    end
    
    def self.init_class_prefix_headers(args, options, classes=[])
      #generate BaClassPrefix.h and PrefixedClassAliases.h
      headers = ["BaClassPrefix", "PrefixedClassAliases"]
      dir = Baproj::Project.open(options.root).include_dir + "ClassPrefix"
      dir.mkpath
      
      headers.each do |header|
        filename = "#{header}.h"
        file = Pathname.new(dir) + filename
        content = generate_header(header, classes, args, options)
        File.open(file, "w") { |f| f.write(content) }
      end
    end
    
    def self.init_headers(args, options)
      xcodeprojs = Badev::XCConfig.collect_xcodeprojs(options.root)
      xcodeprojs.each do |xcodeproj|
        proj = Xcodeproj::Project.open(xcodeproj)
        init_pch_for_proj(proj)
      end
      
      init_class_prefix_headers(args, options)
      
      puts "Run `badev regen_xcconfigs` to generate xcconfigs with a proper GCC_PREFIX_HEADER build settings value" if classes.empty?
    end
    
    def self.regen_class_prefix_headers(args, options)
      # fix any un-prefixed classes
      prefix_classes(options.root)
      files = collect_target_files(options.root)
      classes = collect_classes(files, true)
      
      # generate new BaClassPrefix.h and PrefixedClassAliases.h
      init_class_prefix_headers(args, options, classes)
    end
    
  end
end
