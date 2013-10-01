# badev

A general command-line tool to aid project development in BinaryAge.

## xcconfigs

Managing multiple (10+) xcodeproj/configurations/targets is too much work. The idea is to have (ideally) no build settings in .xcodeproj files and manage them via .xcconfig files (it is diff friendly). By using xcconfig files we can include shared settings sets into different xcodeproj files and manage them from one central place. But it exposes three other problems:

1. our projects are in multiple repositories and they don't have shared storage for xcconfig files, creating yet another submodule just for managing xcconfig files seems to be an overkill
2. xcconfig files do not support conditionals, in xcode you can at most combine two settings sets (at configuration and target level)
3. you can include xcconfig files into other xcconfig files, but you have no way how to read/modify existing settings produced by previous config statements, this limits the way how you could combine/include xcconfig templates

The solution is to generate xcconfig files using `badev` utility.

* `badev init_xcconfigs` searches current directory tree and generates one xcconfig file for each combination xcodeproj-configuration-target. This is one-time bootstrapping phase. After generation you should go to your xcodeprojs and assign these configs to each configuration-target (on target level).

* `badev regen_xcconfigs` searches current directory tree and regenerates xcconfig files which have special header prepared by init_xcconfigs. By default regeneration is done by `bagen` with template named [binaryage](https://github.com/binaryage/badev/blob/master/templates/binaryage.xcconfig.erb). See [templates](https://github.com/binaryage/badev/tree/master/templates) for more info on templating.

## Installation

Install it as:

    gem install badev

Or from git:

    git clone git@github.com:binaryage/badev.git
    gem install xcodeproj commander colored
    export PATH=$PATH:`pwd`/badev/bin
    badev --help