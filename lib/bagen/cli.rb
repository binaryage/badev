require 'commander/import'
require 'colored'

require 'bagen'
require 'bagen/helpers'
require 'bagen/generator'

class Bagen::CLI

  def self.start(*_args)
    program :name, 'bagen'
    program :version, Bagen::VERSION
    program :description, 'A generator of xcconfig files for BinaryAge projects'

    command :generate do |c|
      c.description = 'generates xcconfig file according to given parameters'
      c.syntax = 'bagen generate [--root PATH] [--project_dir PATH] [--output PATH] [arg1] [arg2] ... [argN]'
      c.option '--root PATH', String, 'Specify root path'
      c.option '--output PATH', String, 'Specify PATH to write xcconfig'
      c.option '--project_dir PATH', String, 'Specify PATH of project'
      c.action do |args, options|
        options.default :root => Dir.pwd
        options.default :project_dir => Dir.pwd
        Bagen::Generator::generate(args, options)
      end
    end
  end

end
