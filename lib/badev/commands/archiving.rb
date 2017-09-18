# frozen_string_literal: true

module Badev
  module Archiving
    extend Badev::Helpers

    TMP_DWARFS_DIR = '/tmp/dwarfs'
    TMP_DIR = '/tmp/badev-archiving'
    TMP_PAYLOADS_DIR = '/tmp/payloads'

    def self.copy_pkg_content(pkg, dest)
      puts "Copying PKG content of #{pkg.blue}"

      extractor_dir = File.join(TMP_DIR, 'pkg-extractor')
      sys("rm -rf \"#{extractor_dir}\"") if File.exist? extractor_dir
      sys("mkdir -p \"#{extractor_dir}\"")
      sys("cp \"#{pkg}\" \"#{extractor_dir}\"")

      name = File.basename pkg

      puts "in #{File.expand_path(extractor_dir).blue}"
      indent do
        Dir.chdir(extractor_dir) do
          sys("xar -xf \"#{name}\"")

          Dir.glob('*.pkg') do |file|
            next unless File.directory? file

            puts "in #{File.expand_path(file).blue}"
            indent do
              Dir.chdir(file) do
                if File.exist? 'Payload'
                  sys('mv Payload Payload.gz')
                  sys('gunzip Payload.gz')
                  sys('cpio -id < Payload')

                  sys('find . -maxdepth 1 -type f -delete')

                  dst = File.join(dest, name)
                  sys("mkdir \"#{dst}\"")
                  sys("cp -a * \"#{dst}\"")
                end
              end
            end
          end
        end
      end
    end

    def self.copy_dmg_content(dmg, dest)
      puts "Copying DMG content of #{dmg.blue}"

      indent do
        tmp = File.join(TMP_PAYLOADS_DIR, File.basename(dmg, '.dmg'))
        sys("rm -rf \"#{tmp}\"") if File.exist? tmp
        sys("mkdir -p \"#{tmp}\"")

        res = sys("hdiutil attach \"#{dmg}\" -mountrandom \"#{TMP_PAYLOADS_DIR}\"")
        disk = res.split("\n").select { |l| l.strip =~ /\/dev/ }.first.split("\t").first.strip
        volume = ''
        res.each_line do |line|
          next unless line.match?(/Apple_HFS/)
          volume = line.split("\t")[2].strip
          break
        end

        die('bad disk') unless disk.match?(/\/dev/)
        die('bad volume') if volume.empty?

        sys("cp -r #{volume}/* \"#{tmp}\"")

        Dir.glob(File.join(tmp, '**/*.pkg')) do |pkg|
          copy_pkg_content(pkg, dest)
        end
        sys("hdiutil detach \"#{disk}\"")
      end
    end

    def self.generate_dmg_archive(file)
      sys('rm -rf dmg') if File.exist? 'dmg'
      sys('mkdir dmg')
      copy_dmg_content(file, File.expand_path('dmg'))
    end

    def self.copy_dwarfs(source)
      die "dwarfs missing in #{source.blue}" unless File.exist? source
      sys('rm -rf dwarfs') if File.exist? 'dwarfs'
      sys('mkdir dwarfs')
      sys("cp -a \"#{source}\"/* dwarfs")
    end

    def self.copy_obfuscation_table(source)
      unless File.exist? source
        puts "obfuscation table missing in #{source.blue}".red
        return
      end
      sys("cp \"#{source}\" .")
    end

    def self.write_sha(rev)
      sys('rm sha.txt') if File.exist? 'sha.txt'
      sys("echo #{rev} > sha.txt")
    end

    def self.copy_payload(payloads, name)
      sys('rm payload.txt') if File.exist? 'payload.txt'
      payload = File.join(payloads, name + '.txt')
      if File.exist? payload
        sys("cp \"#{payload}\" payload.txt")
      else
        die "missing payload: #{payload}"
      end
    end

    def self.push_archive(options)
      puts "pushing archive in #{options.archive.blue}"
      Dir.chdir(options.archive) do
        sys('git push && git push --tags')
      end
    end

    def self.archive(options)
      puts "generating archive in #{options.root.blue}"
      Dir.chdir(options.root) do
        dwarfs_base = read_dwarfs_base_dir
        releases = File.expand_path(options.releases)
        payloads = File.expand_path(options.payloads)

        rev = revision

        unless File.exist?(options.archive)
          sys("mkdir -p \"#{options.archive}\"")
          Dir.chdir(options.archive) do
            puts "in #{options.archive.blue}"
            indent do
              sys('git init')
              sys('git commit --allow-empty -m "BIG BANG!"')
              puts 'Important: you still have to setup proper product branch (e.g. totalfinder-archive) and remote repo url for pushing (e.g. binaryage/root).'
            end
          end
        end

        tags = []
        Dir.chdir(options.archive) do
          sys('git pull')
          tags = `git tag`.strip.split "\n"
        end

        Dir.chdir(options.releases) do
          dmgs = []
          Dir.glob('*.dmg').each do |file|
            dmgs << file
          end

          dmgs = dmgs.sort do |a, b|
            va = release_version_from_filename a, '.dmg'
            vb = release_version_from_filename b, '.dmg'
            vb <=> va
          end

          dmgs.reverse!

          dmgs.each do |file|
            name = File.basename(file, '.dmg')
            product = name.split('-')[0]
            product_lowercase = product.downcase
            ver = name.split('-')[1]
            tag = "#{product_lowercase}-archive-v#{ver}"
            next if tags.include? tag

            Dir.chdir(options.archive) do
              puts "in #{options.archive.blue}"
              indent do
                # reset git state - to recover from potential previous failures
                sys('git reset --hard HEAD')
                sys('git clean -fd')

                release = File.join(releases, file)

                generate_dmg_archive(release)
                write_sha(rev)
                copy_dwarfs(File.join(dwarfs_base, ver)) unless options['no-dwarfs']
                copy_obfuscation_table(File.join(dwarfs_base, ver, options.otable)) unless options['no-obfuscation']
                copy_payload(payloads, name)
                sys('rm dwarfs/obfuscation*', true) # quick hack to remove misplaced files

                # commit & tag
                sys('git add . --all')
                # for some reason sys started to freeze on git commit on my machine
                # sys("git commit -a --allow-empty -m \"#{product} release #{ver}\"")
                `git commit -a --allow-empty -m "#{product} release #{ver}"`
                sys("git tag -a #{tag} -m \"#{product} release #{ver}\"")
              end
            end
          end
        end
      end
    end
  end
end
