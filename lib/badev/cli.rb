require 'commander/import'
require 'colored'
require 'fileutils'
require 'pathname'

require "badev"
require "badev/utils/helpers"

require "badev/commands/xcconfig"
require "badev/commands/classprefixer"
require "badev/commands/retagging"
require "badev/commands/pushtags"
require "badev/commands/osax"
require "badev/commands/totalfinder"
require "badev/commands/totalterminal"
require "badev/commands/beautification"
require "badev/commands/payloads"
require "badev/commands/archiving"

class Badev::CLI

  def self.start(*args)
    $indent = ""
    program :name, 'badev'
    program :version, Badev::VERSION
    program :description, 'A helper tool for development in BinaryAge'
    
    global_option('-d', '--dry-run', 'Show what would happen') { $dry_run = true }

    command :archive do |c|
      c.description = 'generates next archive'
      c.syntax = 'badev archive [--root some/dir] [--archive some/dir] [--releases some/dir]'
      c.option '--root PATH', String, 'Specify root path'
      c.option '--archive PATH', String, 'Specify a path for archive'
      c.option '--releases PATH', String, 'Specify a path for releases dir (relative to root)'
      c.option '--payloads PATH', String, 'Specify a path for payloads dir (relative to root)'
      c.option '--otable PATH', String, 'Specify a path for obfuscation table (relative to DWARFS folder)'
      c.option '--no-obfuscation', 'Do not include obfuscation table'
      c.option '--no-dwarfs', 'Do not include DWARFs'
      c.action do |args, options|
        options.default :root => Dir.pwd
        options.default :archive => File.expand_path(File.join(options.root, "..", File.basename(options.root)+"-archive"))
        options.default :releases => "releases"
        options.default :payloads => "payloads"
        options.default :otable => "obfuscation.txt"
        Badev::Archiving::archive(options)
      end
    end

    command :push_archive do |c|
      c.description = 'pushes archive repo'
      c.syntax = 'badev archive [--root some/dir] [--archive some/dir]'
      c.option '--root PATH', String, 'Specify root path'
      c.option '--archive PATH', String, 'Specify a path for archive'
      c.action do |args, options|
        options.default :root => Dir.pwd
        options.default :archive => File.expand_path(File.join(options.root, "..", File.basename(options.root)+"-archive"))
        Badev::Archiving::push_archive(options)
      end
    end

    command :payload do |c|
      c.description = 'generates missing payloads'
      c.syntax = 'badev payload [--root some/dir] [--releases some/dir] [--payloads some/dir]'
      c.option '--root PATH', String, 'Specify root path'
      c.option '--releases PATH', String, 'Specify a path for releases dir (relative to root)'
      c.option '--payloads PATH', String, 'Specify a path for payloads dir (relative to root)'
      c.option '--force', 'Force regeneration'
      c.action do |args, options|
        options.default :root => Dir.pwd
        options.default :releases => "releases"
        options.default :payloads => "payloads"
        Badev::Payloads::generate_payloads(options)
      end
    end

    command :paydiff do |c|
      c.description = 'diff latest payload'
      c.syntax = 'badev paydiff [--root some/dir] [--payloads some/dir]'
      c.option '--root PATH', String, 'Specify root path'
      c.option '--payloads PATH', String, 'Specify a path for payloads dir (relative to root)'
      c.option '--differ PATH', String, 'Specify a diff program to use'
      c.action do |args, options|
        options.default :root => Dir.pwd
        options.default :differ => "ksdiff"
        options.default :payloads => "payloads"
        Badev::Payloads::payload_diff(options)
      end
    end
    
    command :init_xcconfigs do |c|
      c.description = 'creates default xcconfig files for all .xcodeprojs in a directory tree'
      c.syntax = 'badev init_xcconfigs [--root some/dir]'
      c.option '--root PATH', String, 'Specify root path'
      c.option '--add', 'Add xcconfigs to projects'
      c.option '--group GROUP', String, 'Specify group path to add xcconfigs (ignored unless --add used)'
      c.action do |args, options|
        options.default :root => Dir.pwd
        options.default :group => "Configs"
        Badev::XCConfig::init_configs_in_tree(args, options)
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

    command :beautify do |c|
      c.description = 'beautifies source code in a directory tree'
      c.syntax = 'badev beautify [--root some/dir]'
      c.option '--root PATH', String, 'Specify root path'
      c.option '--all', 'Cross submodule boundaries'
      c.option '--filter STRING', String, 'Additional regexp filter, e.g. .cpp'
      c.option '--uncrustify', 'Use uncrustify instead of clang-format'
      c.action do |args, options|
        options.default :root => Dir.pwd
        Badev::Beautification::beautify(options)
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

    command :prefix_classes do |c|
      c.description = 'wraps all compilable ObjC classes with prefixing macro and adds -include /path/to/some/dir/PrefixedClassSupport.h to OTHER_C(PLUSPLUS)FLAGS build settings'
      c.syntax = 'badev prefix_classes [--root some/dir]'
      c.option '--root PATH', String, 'Specify root path'
      c.action do |args, options|
        options.default :root => Dir.pwd
        Badev::ClassPrefixer::prefix_classes(args, options)
      end
    end

    command :init_headers do |c|
      c.description = 'creates BaClassPrefix.h/PrefixedClassAliases.h and a generates precompiled headers for all .xcodeprojs in a directory tree'
      c.syntax = 'badev init_class_prefix_headers [--root some/dir]'
      c.option '--root PATH', String, 'Specify root path'
      c.action do |args, options|
        options.default :root => Dir.pwd
        Badev::ClassPrefixer::init_headers(args, options)
      end
    end

    command :launch_finder do |c|
      c.description = 'launch/activate Finder via AppleScript'
      c.action do |args, options|
        Badev::TotalFinder::launch_finder(options)
      end
    end

    command :quit_finder do |c|
      c.description = 'quit Finder deliberately via AppleScript'
      c.action do |args, options|
        Badev::TotalFinder::quit_finder(options)
      end
    end

    command :kill_finder do |c|
      c.description = 'kill Finder'
      c.action do |args, options|
        Badev::TotalFinder::kill_finder(options)
      end
    end

    command :restart_finder do |c|
      c.description = 'restart Finder deliberately via AppleScript'
      c.action do |args, options|
        Badev::TotalFinder::restart_finder(options)
      end
    end

    command :quit_totalfinder do |c|
      c.description = 'quit Finder+TotalFinder deliberately via AppleScript'
      c.action do |args, options|
        Badev::TotalFinder::quit_totalfinder(options)
      end
    end

    command :restart_totalfinder do |c|
      c.description = 'restart Finder+TotalFinder deliberately via AppleScript'
      c.action do |args, options|
        Badev::TotalFinder::restart_totalfinder(options)
      end
    end

    command :inject_totalfinder do |c|
      c.description = 'attempt to inject TotalFinder'
      c.action do |args, options|
        Badev::TotalFinder::inject_totalfinder(options)
      end
    end

    command :open_totalfinder do |c|
      c.description = 'open ~/Applications/TotalFinder.app'
      c.action do |args, options|
        Badev::TotalFinder::open_totalfinder(options)
      end
    end

    command :crash_totalfinder do |c|
      c.description = 'externally crash TotalFinder'
      c.action do |args, options|
        Badev::TotalFinder::crash_totalfinder(options)
      end
    end

    command :tfrmd do |c|
      c.description = 'remove TotalFinder\'s dev installation'
      c.action do |args, options|
        Badev::TotalFinder::remove_dev(options)
      end
    end

    command :tfrmr do |c|
      c.description = 'remove TotalFinder\'s retail installation'
      c.action do |args, options|
        Badev::TotalFinder::remove_retail(options)
      end
    end
    
    command :authorize_send do |c|
      c.description = 'get rid of those annoying authorization dialogs during development'
      c.action do |args, options|
        Badev::Osax::authorize_send(options)
      end
    end

    command :launch_terminal do |c|
      c.description = 'launch/activate Terminal via AppleScript'
      c.action do |args, options|
        Badev::TotalTerminal::launch_terminal(options)
      end
    end

    command :quit_terminal do |c|
      c.description = 'quit Terminal deliberately via AppleScript'
      c.action do |args, options|
        Badev::TotalTerminal::quit_terminal(options)
      end
    end

    command :kill_terminal do |c|
      c.description = 'kill Terminal'
      c.action do |args, options|
        Badev::TotalTerminal::kill_terminal(options)
      end
    end

    command :restart_terminal do |c|
      c.description = 'restart Terminal deliberately via AppleScript'
      c.action do |args, options|
        Badev::TotalTerminal::restart_terminal(options)
      end
    end

    command :quit_totalterminal do |c|
      c.description = 'quit Terminal+TotalTerminal deliberately via AppleScript'
      c.action do |args, options|
        Badev::TotalTerminal::quit_totalterminal(options)
      end
    end

    command :restart_totalterminal do |c|
      c.description = 'restart Terminal+TotalTerminal deliberately via AppleScript'
      c.action do |args, options|
        Badev::TotalTerminal::restart_totalterminal(options)
      end
    end

    command :inject_totalterminal do |c|
      c.description = 'attempt to inject TotalTerminal'
      c.action do |args, options|
        Badev::TotalTerminal::inject_totalterminal(options)
      end
    end

    command :open_totalterminal do |c|
      c.description = 'open ~/Applications/TotalTerminal.app'
      c.action do |args, options|
        Badev::TotalTerminal::open_totalterminal(options)
      end
    end

    command :crash_totalterminal do |c|
      c.description = 'externally crash TotalTerminal'
      c.action do |args, options|
        Badev::TotalTerminal::crash_totalterminal(options)
      end
    end

    command :ttrmd do |c|
      c.description = 'remove TotalTerminal\'s dev installation'
      c.action do |args, options|
        Badev::TotalTerminal::remove_dev(options)
      end
    end

    command :ttrmr do |c|
      c.description = 'remove TotalTerminal\'s retail installation'
      c.action do |args, options|
        Badev::TotalTerminal::remove_retail(options)
      end
    end

    command :deauthorize_send do |c|
      c.description = 're-enable authorization dialogs'
      c.action do |args, options|
        Badev::Osax::deauthorize_send(options)
      end
    end

  end

end

