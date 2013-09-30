all templates are simply ERB files, they produce final xcconfig file

you can use Ruby powers to generate the file, additionally you have these available:

@template - template name
@project - Xcode project name
@configuration - Xcode configuration name
@target - Xcode target name
@args - all arguments passed to bagen utility

include('some/path') - include partial template

note: xcconfig parameters can be overriden by subsequent lines of the config file.
This is good and handy for inclusion more specialized templates below general ones.
But it causes troubles for definitons of arrays of values or when template wants to concatenate something to existing values.
Solution is to track these as ruby variables and emit them in last step. See shared_begin.xcconfig and shared_end.xcconfig.
