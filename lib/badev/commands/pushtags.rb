# frozen_string_literal: true

module Badev
  module PushTags
    extend Badev::Helpers

    def self.walk_submodules(dir, level)
      Dir.chdir dir do
        indent do
          puts "in #{dir.blue}"

          submodules = []
          submodules = `grep path .gitmodules | sed 's/.*= //'`.split "\n" if File.exist? '.gitmodules'
          submodules.each do |path|
            sub_path = File.join(dir, path)
            walk_submodules(sub_path, level + 1)
          end

          indent do
            sys('git push && git push --tags', true)
          end
        end
      end
    end

    def self.push_tags(options)
      msg = "pushing tags in #{options.root.blue}"
      puts msg

      indent do
        Dir.chdir options.root do
          walk_submodules(options.root, 0)
        end
      end
    end
  end
end
