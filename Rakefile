# frozen_string_literal: true

require 'bundler/gem_tasks'

desc 'update readme with latest help'
task :update_readme do
  help = `bin/badev --help`
  indented_help = "\n"
  help.each_line do |line|
    indented_help = "#{indented_help}  #{line}"
  end

  readme = File.read('README.md')

  new_readme = []
  removing = false
  readme.each_line do |line|
    removing = false if line.match?(/## /)
    new_readme << line unless removing
    if line.match?(/## usage/)
      removing = true
      new_readme << indented_help
    end
  end

  File.write('README.md', new_readme.join)
  puts 'README.md updated'
end

desc 'install locally'
task :install do
  `gem build`
  `gem install badev-*.gem`
end
