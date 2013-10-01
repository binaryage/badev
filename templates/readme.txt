All templates are simply Ruby's ERB files, they produce final xcconfig file.

You should use your Ruby powers to generate the file,
additionally you have these vars/methods available:

@template - template name
@project - Xcode project name
@configuration - Xcode configuration name
@target - Xcode target name
@args - all arguments passed to bagen utility

include('some/path') - include partial template

note: xcconfig parameters can be overriden by subsequent lines of the config file.
This is good and handy for inclusion more specialized templates below general ones.
But it causes troubles for definitons of arrays of values or when template wants read/alter existing values.
My solution is to track these as ruby variables and emit them in the last step.
See shared_begin.xcconfig.erb and shared_end.xcconfig.erb.

Also note that all comments will be stripped out and empty newlines will be removed.
If you want your comments to persist use tripple slash comment:
/// this comment will survive stripping