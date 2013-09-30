require 'commander/import'
require 'colored'

require "badev"
require "badev/helpers"
require "badev/xcconfig"

class Badev::CLI

  def self.start(*args)
    program :name, 'badev'
    program :version, Badev::VERSION
    program :description, 'A helper tool for development in BinaryAge'

    command :init_xcconfigs do |c|
      c.description = 'creates default xcconfig files for all .xcodeprojs in a directory tree'
      c.syntax = 'badev init_xcconfigs [--root some/dir]'
      c.option '--root PATH', String, 'Specify root path'
      c.action do |args, options|
        options.default :root => Dir.pwd
        Badev::XCConfig::init_configs_in_tree(options.root)
      end
    end

    command :regen_xcconfigs do |c|
      c.description = 'regenerates xcconfig files for all .xcodeprojs in a directory tree'
      c.syntax = 'badev regen_xcconfigs [--root some/dir]'
      c.option '--root PATH', String, 'Specify root path'
      c.action do |args, options|
        options.default :root => Dir.pwd
        Badev::XCConfig::regen_configs_in_tree(options.root)
      end
    end
  end

end

