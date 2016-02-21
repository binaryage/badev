module Badev
  module Retagging

    extend Badev::Helpers
    
    def self.prefix_tag(prefix, tag)
      "#{prefix}#{tag}"
    end
    
    def self.walk_submodules(dir, prefixed_tag, sha, level)
      Dir.chdir dir do
        indent do
          puts "in #{dir.blue}"

          indent do
            unless sha then
              puts "unknown sha (the submodule wasn't present in this revision) => skipping".red
            else
              if level>0 then
                tag_exists = !(`git tag | grep #{prefixed_tag}`.strip.empty?)
                if tag_exists and not $options.force then
                  existing_sha = `git rev-list -1 '#{prefixed_tag}'`.strip
                  if existing_sha != sha then
                    puts "the tag '#{prefixed_tag}' already exists and differs => skipping (use --force to overwrite it)".red
                  else
                    puts "the tag '#{prefixed_tag}' already exists and matches => nothing to do".green
                  end
                else
                  sys("git tag -d #{prefixed_tag}") if tag_exists
                  sys("git tag -a '#{prefixed_tag}' #{sha} -m \"retagged from parent repo\"", true)
                end
              end
            end
          end
      
          submodules = []
          submodules = `grep path .gitmodules | sed 's/.*= //'`.split "\n" if File.exists? ".gitmodules"
          submodules.each do |path|
            sub_path = File.join(dir, path)
            sub_sha = `git ls-tree #{sha} #{path}`.split(" ")[2]
            walk_submodules(sub_path, prefixed_tag, sub_sha, level+1)
          end
        end
      end
    end

    def self.retag(options)
      $options = options
      msg = "retagging in #{$options.root.blue}"
      msg += " with prefix #{$options.prefix.magenta}" unless $options.prefix.empty?
      puts msg

      indent do
        Dir.chdir $options.root do
          if $options.all then
            tags = `git tag`.strip.split "\n" # gives me all tags
          else
            tags = [`git describe --tags --abbrev=0`.strip] # gives me the last tag on current branch
          end

          tags.each do |tag|
            puts "processing tag #{tag.green}"
            sha = `git rev-list -1 '#{tag}'`.strip # this is the sha the tag points to
            prefixed_tag = prefix_tag($options.prefix, tag)
            walk_submodules($options.root, prefixed_tag, sha, 0)
          end
        end
      end
    end

  end
end
