require 'commander/import'
require 'colored'

require "bagen"
require "bagen/helpers"
require "bagen/generator"

class Bagen::CLI

  def self.start(*args)
    program :name, 'bagen'
    program :version, Bagen::VERSION
    program :description, 'A generator of xcconfig files for BinaryAge projects'

    command :generate do |c|
      c.description = 'generates xcconfig file according to given parameters'
      c.syntax = 'bagen generate [arg1] [arg2] ... [argN]'
      c.action do |args, options|
        Bagen::Generator::generate(args)
      end
    end
  end

end

