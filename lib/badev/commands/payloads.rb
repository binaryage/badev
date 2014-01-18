module Badev
  module Payloads
    extend Badev::Helpers
    
    TMP_PAYLOADS_DIR = "/tmp/payloads"
    
    def self.generate_payload_for_pkg(options, tmp, pkg)
      tree = ""
      exes = ""
      deps = ""
      symbols = ""

      extractor_dir = File.join(tmp, "payload-extractor")
      sys("rm -rf \"#{extractor_dir}\"") if File.exist? extractor_dir
      sys("mkdir -p \"#{extractor_dir}\"")
      sys("cp \"#{pkg}\" \"#{extractor_dir}\"")

      name = File.basename pkg

      Dir.chdir(extractor_dir) do
        sys("xar -xf \"#{name}\"")
        
        Dir.glob("*.pkg") do |file|
          next unless File.directory? file
          
          Dir.chdir(file) do
            if (File.exist? "Payload") then
              sys("mv Payload Payload.gz")
              sys("gunzip Payload.gz")
              sys("cpio -id < Payload")
            end

            tree = `tree --dirsfirst -apsugif`
            binaries = []
            Dir.glob("**/Frameworks/*.framework") do |framework|
              base = File.basename framework, ".framework"
              full = File.join(framework, base)
              binaries << full
            end
            Dir.glob("**/MacOS/*") do |exe|
              binaries << exe
            end

            binaries.each do |binary|
              exes += `file "#{binary}"` + "\n"
            end

            binaries.each do |binary|
              lines = `otool -L "#{binary}"`.split("\n")
              lines = [lines[0]].concat(lines[1..-1].sort)
              deps += lines.join("\n")+"\n"
              deps += "\n"
            end

            binaries.each do |binary|
              symbols += "nm -aj \"#{binary}\"\n"
              symbols += `nm -aj "#{binary}"` + "\n"
              symbols += "\n"
            end
          end
        end
      end

      res = ""
      res << "\n"
      res << "#{name}\n"
      res << "=======================================================================\n"
      res << tree
      res << "\n"
      res << exes
      res << "\n"
      res << deps
      res << "\n"
      res << symbols
      res
    end

    def self.generate_payload(options, dmg, out)
      puts "generating payload for #{dmg.blue}".green
      return if $dry_run

      indent do
        tmp = File.join(TMP_PAYLOADS_DIR, File.basename(dmg, ".dmg"))
        sys("rm -rf \"#{tmp}\"") if File.exist? tmp
        sys("mkdir -p \"#{tmp}\"")

        res = sys("hdiutil attach \"#{dmg}\" -mountrandom \"#{TMP_PAYLOADS_DIR}\"")
        disk = res.split("\n")[0].split("\t")[0]
        volume = ""
        res.each_line do |line|
          next unless line =~ /Apple_HFS/
          volume = line.split("\t")[2].strip
          break
        end

        die("bad disk") unless disk =~ /\/dev/
        die("bad volume") if volume.empty?

        sys("cp -r #{volume}/* \"#{tmp}\"")

        tree1 = ""
        Dir.chdir(tmp) do
          tree1 = `tree --dirsfirst -apsugif`
        end

        pkgs = []
        Dir.glob(File.join(tmp, "**/*.pkg")) do |pkg|
          pkgs << generate_payload_for_pkg(options, tmp, pkg)
        end


        outdir = File.dirname out
        `mkdir -p #{outdir}` unless File.exist? outdir
        File.open(out, "w") do |f|
          f << "BASIC DMG LAYOUT\n"
          f << "================\n"
          f << tree1

          pkgs.each do |pkg|
            f << pkg
          end
        end

        sys("hdiutil detach #{disk}")
        
        puts "-> ".green + out.blue
      end
    end
    
    def self.generate_payloads(options)
      puts "generating payloads in #{options.root.blue}"
      Dir.chdir(options.root) do
        Dir.glob(File.join(options.releases, "*.dmg")).each do |file|
          name = File.basename(file, ".dmg")
          dest = File.join(options.payloads, name+".txt")
          next if not options.force and File.exist? dest
          generate_payload(options, file, dest)
        end
      end
    end
    
    def self.payload_diff(options)
      puts "diff-ing payloads in #{options.root.blue}"
      indent do
        Dir.chdir(options.root) do
          res = sys("ls -1 \"#{options.payloads}\"/*.txt", false, true).split("\n")
          return if $dry_run

          res = res.sort do |a, b|
            va = release_version_from_filename a
            vb = release_version_from_filename b
            vb<=>va
          end

          sys("\"#{options.differ}\" \"#{res[1]}\" \"#{res[0]}\"")
        end
      end
    end

  end
end
