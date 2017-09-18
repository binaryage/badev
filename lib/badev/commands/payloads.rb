# frozen_string_literal: true

module Badev
  module Payloads
    extend Badev::Helpers

    TMP_PAYLOADS_DIR = '/tmp/payloads'

    module_function

    def generate_tree
      `tree --dirsfirst -apsugif`
    end

    def generate_binaries
      binaries = []
      Dir.glob('**/*') do |file|
        next unless File.executable? file
        next unless `file "#{file}"`.match?(/Mach-O/)
        binaries << file
      end

      binaries.reject! { |file| File.symlink? file }

      binaries
    end

    def generate_exes(binaries)
      exes = ''
      binaries.each do |binary|
        exes += `file "#{binary}"` + "\n"
      end
      exes
    end

    def generate_deps(binaries)
      deps = ''
      binaries.each do |binary|
        lines = `otool -L "#{binary}"`.split("\n")
        lines = [lines[0]].concat(lines[1..-1].sort)
        deps += lines.join("\n") + "\n"
        deps += "\n"
      end
      deps
    end

    def generate_symbols(binaries)
      symbols = ''
      binaries.each do |binary|
        symbols += "nm -aj \"#{binary}\"\n"
        symbols += `nm -aj "#{binary}"` + "\n"
        symbols += "\n"
      end
      symbols
    end

    def generate_payload_for_pkg(_options, tmp, pkg)
      tree = ''
      exes = ''
      deps = ''
      symbols = ''

      extractor_dir = File.join(tmp, 'payload-extractor')
      sys("rm -rf \"#{extractor_dir}\"") if File.exist? extractor_dir
      sys("mkdir -p \"#{extractor_dir}\"")
      sys("cp \"#{pkg}\" \"#{extractor_dir}\"")

      name = File.basename pkg

      Dir.chdir(extractor_dir) do
        # this mv is here to prevent name clash, Asepsis.pkg archive file was extracted into Asepsis.pkg folder
        sys("mv \"#{name}\" \"__#{name}\"")
        sys("xar -xf \"__#{name}\"")

        Dir.glob('*.pkg') do |path|
          next unless File.directory? path

          Dir.chdir(path) do
            if File.exist? 'Payload'
              sys('mv Payload Payload.gz')
              sys('gunzip Payload.gz')
              sys('cpio -id < Payload')
            end

            tree = generate_tree
            binaries = generate_binaries
            exes = generate_exes(binaries)
            deps = generate_deps(binaries)
            symbols = generate_symbols(binaries)
          end
        end
      end

      res = ''
      res += "\n"
      res += "#{name}\n"
      res += "=======================================================================\n"
      res += tree
      res += "\n"
      res += exes
      res += "\n"
      res += deps
      res += "\n"
      res += symbols
      res
    end

    def symbol_obfuscation_partial?(name)
      name =~ /\[(.*)\]/
      parts = Regexp.last_match(1).strip.split(' ')
      sel = parts[1]
      return false unless sel.match?(/^TF\$/)
      chunks = sel.split(':')
      chunks.each do |chunk|
        next if chunk.empty?
        return true unless chunk.match?(/^TF\$/)
      end
      false
    end

    def symbol_obfuscated?(name)
      name =~ /\[(.*)\]/
      parts = Regexp.last_match(1).strip.split(' ')
      sel = parts[1]
      sel =~ /TF\$/
    end

    def generate_obfuscation_report(dwarf_folder)
      base_dir = File.expand_path(dwarf_folder)
      ignores_file = File.join(base_dir, '.obfuscation-ignores')
      mapping_table_file = File.join(base_dir, 'obfuscation.txt')
      used_symbols_file = File.join(base_dir, 'obfuscation_used_symbols.txt')

      unless File.exist? ignores_file
        puts 'skipping obfuscation report'.red + " - #{ignores_file.yellow} is missing"
        return ''
      end

      # parse ignores file
      ignores_data = File.read(ignores_file).split("\n")
      subexprs = []
      ignores_data.each do |sre|
        meat = sre.split('#')[0] # strip comments
        next unless meat
        meat.strip!
        next if meat.empty? # skip empty lines
        subexprs << Regexp.new(meat)
      end
      ignores_regexps = Regexp.union(subexprs)

      # parse mapping table
      mapping = {}
      mapping_data = File.read(mapping_table_file).split("\n")
      mapping_data.each do |element|
        parts = element.split(' ')
        mapping[parts[0]] = parts[1]
      end

      # process used_symbols_file
      symbols = []
      symbols_data = File.read(used_symbols_file).split("\n")
      symbols_data.each do |symbol|
        s = {}
        s[:raw] = symbol
        s[:translated] = symbol.gsub(/(TF\$[a-zA-Z0-9_]+)/) do
          key = mapping[Regexp.last_match(1)]
          die("unable to translate symbol '#{Regexp.last_match(1)}'") unless key
          key
        end
        s[:ignored] = s[:translated] =~ ignores_regexps
        unless s[:ignored]
          s[:partial] = symbol_obfuscation_partial?(s[:raw])
          unless s[:partial]
            s[:fixme] = !symbol_obfuscated?(s[:raw])
            s[:ok] = true unless s[:fixme]
          end
        end
        symbols << s
      end

      ignored_count = 0
      partial_count = 0
      ok_count = 0
      fixme_count = 0

      symbols.each do |symbol|
        ignored_count += 1 if symbol[:ignored]
        partial_count += 1 if symbol[:partial]
        ok_count += 1 if symbol[:ok]
        fixme_count += 1 if symbol[:fixme]
      end

      res = []
      res << "Detected #{symbols.size} methods in our classes "
      res << "(#{ignored_count} ignored, #{ok_count} ok, #{fixme_count} need fixing and #{partial_count} partial)"
      if fixme_count.positive?
        res << ''
        res << "Non-obfuscated (#{fixme_count}) - need fixing or add them into ignores:"
        symbols.each do |symbol|
          res << "  #{symbol[:translated]}" if symbol[:fixme]
        end
        res << ''
      end
      if partial_count.positive?
        res << ''
        res << "Partially obfuscated (#{partial_count}) - need fixing:"
        symbols.each do |symbol|
          res << "  #{symbol[:translated]}" if symbol[:partial]
        end
      end
      res.join("\n")
    end

    def generate_payload(options, dmg, out)
      puts "generating payload for #{dmg.blue}".green
      return if dry_run?

      indent do
        tmp = File.join(TMP_PAYLOADS_DIR, File.basename(dmg, '.dmg'))
        sys("rm -rf \"#{tmp}\"") if File.exist? tmp
        sys("mkdir -p \"#{tmp}\"")

        res = sys("hdiutil attach \"#{dmg}\" -mountrandom \"#{TMP_PAYLOADS_DIR}\"")
        disks = res.split("\n").select { |l| l.strip.match?(/^\/dev/) }
        disk = disks.first.split("\t").first.strip
        volume = ''
        res.each_line do |line|
          next unless line.include?(TMP_PAYLOADS_DIR)
          volume = line.split("\t")[2].strip
          break
        end

        die('bad disk') unless disk.match?(/^\/dev/)
        die('bad volume') if volume.empty?

        sys("cp -r #{volume}/* \"#{tmp}\"")

        tree1 = ''
        Dir.chdir(tmp) do
          tree1 = `tree --dirsfirst -apsugif`
        end

        pkgs = []
        Dir.glob(File.join(tmp, '**/*.pkg')) do |pkg|
          pkgs << generate_payload_for_pkg(options, tmp, pkg)
        end

        obfuscation_report = ''
        Dir.chdir(options.root) do
          dwarfs_base = read_dwarfs_base_dir
          if dwarfs_base
            name = File.basename(dmg, '.dmg')
            ver = name.split('-')[1]
            obfuscation_report = generate_obfuscation_report(File.join(dwarfs_base, ver))
          end
        end

        outdir = File.dirname out
        `mkdir -p #{outdir}` unless File.exist? outdir
        File.open(out, 'w') do |f|
          unless obfuscation_report.empty?
            f << "OBFUSCATION REPORT\n"
            f << "==================\n"
            f << obfuscation_report
            f << "\n\n"
          end

          f << "BASIC DMG LAYOUT\n"
          f << "================\n"
          f << tree1

          pkgs.each do |pkg|
            f << pkg
          end
        end

        sys("hdiutil detach #{disk}")

        puts '-> '.green + out.blue
      end
    end

    def generate_payloads(options)
      puts "generating payloads in #{options.root.blue}"
      Dir.chdir(options.root) do
        Dir.glob(File.join(options.releases, '*.dmg')).each do |file|
          name = File.basename(file, '.dmg')
          dest = File.join(options.payloads, name + '.txt')
          next if !options.force && File.exist?(dest)
          generate_payload(options, file, dest)
        end
      end
    end

    def payload_diff(options)
      puts "diff-ing payloads in #{options.root.blue}"
      indent do
        Dir.chdir(options.root) do
          res = sys("ls -1 \"#{options.payloads}\"/*.txt", false, true).split("\n")
          return if dry_run?

          res = res.sort do |a, b|
            va = release_version_from_filename a
            vb = release_version_from_filename b
            vb <=> va
          end

          sys("\"#{options.differ}\" \"#{res[1]}\" \"#{res[0]}\"")
        end
      end
    end
  end
end
