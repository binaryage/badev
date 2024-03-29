# badev

A general command-line tool to aid project development in BinaryAge.

## installation

    git clone git@github.com:binaryage/badev.git
    bundle install
    export PATH=$PATH:`pwd`/badev/bin
    badev --help

## usage

    NAME:

      badev

    DESCRIPTION:

      A helper tool for development in BinaryAge

    COMMANDS:

      archive             generates next archive
      authorize_send      get rid of those annoying authorization dialogs during development
      beautify            beautifies source code in a directory tree
      crash_totalfinder   externally crash TotalFinder
      deauthorize_send    re-enable authorization dialogs
      help                Display global or [command] help documentation
      init_xcconfigs      creates default xcconfig files for all .xcodeprojs in a directory tree
      inject_totalfinder  attempt to inject TotalFinder
      kill_finder         kill Finder
      launch_finder       launch/activate Finder via AppleScript
      open_totalfinder    open ~/Applications/TotalFinder.app
      paydiff             diff latest payload
      payload             generates missing payloads
      push_archive        pushes archive repo
      push_tags           pushes tags from all submodules
      quit_finder         quit Finder deliberately via AppleScript
      quit_totalfinder    quit Finder+TotalFinder deliberately via AppleScript
      regen_xcconfigs     regenerates xcconfig files for all .xcodeprojs in a directory tree
      restart_finder      restart Finder deliberately via AppleScript
      restart_totalfinder restart Finder+TotalFinder deliberately via AppleScript
      retag               adds missing tags to submodules according to last tag in root repo
      tfrmd               remove TotalFinder's dev installation
      tfrmr               remove TotalFinder's retail installation

    GLOBAL OPTIONS:

      -d, --dry-run
          Show what would happen

      -h, --help
          Display help documentation

      -v, --version
          Display version information

      -t, --trace
          Display backtrace when an error occurs

## xcconfigs

Managing multiple (10+) xcodeproj/configurations/targets is too much work. The idea is to have (ideally) no build settings in .xcodeproj files and manage them via .xcconfig files (it is diff friendly). By using xcconfig files we can include shared settings sets into different xcodeproj files and manage them from one central place. But it exposes three other problems:

1. our projects are in multiple repositories and they don't have shared storage for xcconfig files, creating yet another submodule just for managing xcconfig files seems to be an overkill
2. xcconfig files do not support conditionals, in xcode you can at most combine two settings sets (at configuration and target level)
3. you can include xcconfig files into other xcconfig files, but you have no way how to read/modify existing settings produced by previous config statements, this limits the way how you could combine/include xcconfig templates

The solution is to generate xcconfig files using `badev` utility.

* `badev init_xcconfigs` searches current directory tree and generates one xcconfig file for each combination xcodeproj-configuration-target. This is one-time bootstrapping phase. After generation you should go to your xcodeprojs and assign these configs to each configuration-target (on target level).

* `badev regen_xcconfigs` searches current directory tree and regenerates xcconfig files which have special header prepared by init_xcconfigs. By default regeneration is done by `bagen` with template named [binaryage](https://github.com/binaryage/badev/blob/master/templates/binaryage.xcconfig.erb). See [templates](https://github.com/binaryage/badev/tree/master/templates) for more info on templating.
