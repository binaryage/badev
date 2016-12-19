require 'bundler/gem_tasks'

desc 'update readme with latest help'
task :update_readme do
  help = `bin/badev --help`
  indented_help = "\n"
  help.each_line do |line|
    indented_help << '  ' + line
  end
  
  readme = File.read('README.md')
  
  new_readme = []
  removing = false
  readme.each_line do |line|
    removing = false if line =~ /## /
    new_readme << line unless removing
    if line =~ /## usage/ then
      removing = true
      new_readme << indented_help
    end
  end
  
  File.write('README.md', new_readme.join())
  puts 'README.md updated'
end

