require 'commander/import'
require 'colored'

require "badev"
require "badev/utils/helpers"

require "badev/commands/xcconfig"
require "badev/commands/retagging"
require "badev/commands/pushtags"

class Badev::CLI

  def self.start(*args)
    $indent = ""
    program :name, 'badev'
    program :version, Badev::VERSION
    program :description, 'A helper tool for development in BinaryAge'
    
    global_option('-d', '--dry-run', 'Show what would happen') { $dry_run = true }

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

    command :retag do |c|
      c.description = 'adds missing tags to submodules according to last tag in root repo'
      c.syntax = 'badev retag [--root some/dir]'
      c.option '--all', 'Retag all existing tags'
      c.option '--force', 'Force removing existing tags'
      c.option '--root PATH', String, 'Specify root path'
      c.option '--prefix PREFIX', String, 'Specify prefix'
      c.action do |args, options|
        options.default :root => Dir.pwd
        retag_file = File.join(options.root, ".retag")
        retag_prefix = ""
        retag_prefix = File.read(retag_file).strip if File.exists?(retag_file)
        options.default :prefix => retag_prefix
        Badev::Retagging::retag(options)
      end
    end
    
    command :push_tags do |c|
      c.description = 'pushes tags from all submodules'
      c.syntax = 'badev push_tags [--root some/dir]'
      c.option '--root PATH', String, 'Specify root path'
      c.action do |args, options|
        options.default :root => Dir.pwd
        Badev::PushTags::push_tags(options)
      end
    end
    
  end

end

