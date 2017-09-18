# frozen_string_literal: true

require 'commander/import'

require 'bagen'
require 'bagen/colored2'
require 'bagen/helpers'
require 'bagen/generator'

module Bagen
  class CLI
    def self.start(*_args)
      always_trace!
      program :name, 'bagen'
      program :version, Bagen::VERSION
      program :description, 'A generator of xcconfig files for BinaryAge projects'
      default_command :help

      command :generate do |c|\
        c.description = 'generates xcconfig file according to given parameters'
        c.syntax = 'bagen generate [--root PATH] [--project_dir PATH] [--output PATH] [arg1] [arg2] ... [argN]'
        c.option '--root PATH', String, 'Specify root path'
        c.option '--output PATH', String, 'Specify PATH to write xcconfig'
        c.option '--project_dir PATH', String, 'Specify PATH of project'
        c.action do |args, options|
          options.default root: Dir.pwd
          options.default project_dir: Dir.pwd
          Bagen::Generator.generate(args, options)
        end
      end
    end
  end
end
