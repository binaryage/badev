# badev

A general command-line tool to aid project development in BinaryAge.

## installation

    git clone git@github.com:binaryage/badev.git
    bundle install
    export PATH=$PATH:`pwd`/badev/bin
    badev --help
## usage

    badev
  
    A helper tool for development in BinaryAge
  
    Commands:
      archive              generates next archive
      authorize_send       get rid of those annoying authorization dialogs during development
      beautify             beautifies source code in a directory tree
      crash_totalfinder    externally crash TotalFinder
      crash_totalterminal  externally crash TotalTerminal
      deauthorize_send     re-enable authorization dialogs
      help                 Display global or [command] help documentation.
      init_headers         creates BaClassPrefix.h/PrefixedClassAliases.h and a generates precompiled headers for all .xcodeprojs in a directory tree
      init_xcconfigs       creates default xcconfig files for all .xcodeprojs in a directory tree
      inject_totalfinder   attempt to inject TotalFinder
      inject_totalterminal attempt to inject TotalTerminal
      kill_finder          kill Finder
      kill_terminal        kill Terminal
      launch_finder        launch/activate Finder via AppleScript
      launch_terminal      launch/activate Terminal via AppleScript
      open_totalfinder     open ~/Applications/TotalFinder.app
      open_totalterminal   open ~/Applications/TotalTerminal.app
      paydiff              diff latest payload
      payload              generates missing payloads
      prefix_classes       wraps all compilable ObjC classes with prefixing macro and regenerates BaClassPrefix.h/PrefixedClassAliases.h
      push_archive         pushes archive repo
      push_tags            pushes tags from all submodules
      quit_finder          quit Finder deliberately via AppleScript
      quit_terminal        quit Terminal deliberately via AppleScript
      quit_totalfinder     quit Finder+TotalFinder deliberately via AppleScript
      quit_totalterminal   quit Terminal+TotalTerminal deliberately via AppleScript
      regen_xcconfigs      regenerates xcconfig files for all .xcodeprojs in a directory tree
      restart_finder       restart Finder deliberately via AppleScript
      restart_terminal     restart Terminal deliberately via AppleScript
      restart_totalfinder  restart Finder+TotalFinder deliberately via AppleScript
      restart_totalterminal restart Terminal+TotalTerminal deliberately via AppleScript
      retag                adds missing tags to submodules according to last tag in root repo
      tfrmd                remove TotalFinder's dev installation
      tfrmr                remove TotalFinder's retail installation
      ttrmd                remove TotalTerminal's dev installation
      ttrmr                remove TotalTerminal's retail installation
  
    Global Options:
      -d, --dry-run        Show what would happen 
      -h, --help           Display help documentation 
      -v, --version        Display version information 
      -t, --trace          Display backtrace when an error occurs 
  
## xcconfigs

Managing multiple (10+) xcodeproj/configurations/targets is too much work. The idea is to have (ideally) no build settings in .xcodeproj files and manage them via .xcconfig files (it is diff friendly). By using xcconfig files we can include shared settings sets into different xcodeproj files and manage them from one central place. But it exposes three other problems:

1. our projects are in multiple repositories and they don't have shared storage for xcconfig files, creating yet another submodule just for managing xcconfig files seems to be an overkill
2. xcconfig files do not support conditionals, in xcode you can at most combine two settings sets (at configuration and target level)
3. you can include xcconfig files into other xcconfig files, but you have no way how to read/modify existing settings produced by previous config statements, this limits the way how you could combine/include xcconfig templates

The solution is to generate xcconfig files using `badev` utility.

* `badev init_xcconfigs` searches current directory tree and generates one xcconfig file for each combination xcodeproj-configuration-target. This is one-time bootstrapping phase. After generation you should go to your xcodeprojs and assign these configs to each configuration-target (on target level).

* `badev regen_xcconfigs` searches current directory tree and regenerates xcconfig files which have special header prepared by init_xcconfigs. By default regeneration is done by `bagen` with template named [binaryage](https://github.com/binaryage/badev/blob/master/templates/binaryage.xcconfig.erb). See [templates](https://github.com/binaryage/badev/tree/master/templates) for more info on templating.