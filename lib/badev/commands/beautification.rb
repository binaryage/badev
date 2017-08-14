module Badev
  module Beautification
    extend Badev::Helpers

    CLANG_FORMAT = File.join(TOOLS_DIR, 'clang-format')
    CLANG_FORMAT_CONFIG = File.join(CONFIGS_DIR, '.clang-format')
    UNCRUSTIFY_CONFIG = File.join(CONFIGS_DIR, 'uncrustify.cfg')
    BEAUTIFY_CONFIG_NAME = '.beautify'

    def self.temp_clang_config(config)
      `cp "#{config}" .clang-format`
      begin
        yield()
      ensure
        `rm .clang-format`
      end
    end

    def self.reformat(options, file)
      if options.uncrustify
        sys("uncrustify -c \"#{UNCRUSTIFY_CONFIG}\" --replace --no-backup --mtime \"#{file}\"")
      else
        sys("\"#{CLANG_FORMAT}\" -i \"#{file}\"")
      end
    end

    def self.walk_submodules(options, dir)
      Dir.chdir dir do
        indent do
          puts "in #{dir.blue}"

          indent do
            excludes = []
            if File.exists? BEAUTIFY_CONFIG_NAME
              excludes = File.read(BEAUTIFY_CONFIG_NAME).strip.split("\n").map { |r| Regexp.new r }
              puts "using #{BEAUTIFY_CONFIG_NAME.blue} config with #{excludes.size} excludes"
            end

            filter = Regexp.new (options.filter or '')
            files = `git ls-tree -r HEAD --name-only`.strip.split("\n") # list files under version control

            temp_clang_config(CLANG_FORMAT_CONFIG) do
              files.each do |file|
                next unless file=~/\.(mm|m|c|h|cc|cpp|hpp)$/
                next unless file=~filter
                unless File.exist? file
                  puts "#{'skipping'.red} #{file.blue} - no longer exists"
                  next
                end
                matched_some_exclude = false
                excludes.each do |exclude|
                  if file=~exclude
                    matched_some_exclude = true
                    break
                  end
                end
                next if matched_some_exclude
                reformat(options, file)
              end
            end

          end

          if options.all
            submodules = []
            submodules = `grep path .gitmodules | sed 's/.*= //'`.split "\n" if File.exists? '.gitmodules'
            submodules.each do |path|
              sub_path = File.join(dir, path)
              walk_submodules(options, sub_path)
            end
          end
        end
      end
    end

    def self.beautify(options)
      beautifier = 'clang-format'
      msg = "beautifing sources in #{options.root.blue} using #{beautifier.magenta}"
      puts msg

      walk_submodules(options, options.root)
    end

  end
end
