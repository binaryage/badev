# frozen_string_literal: true

require 'pathname'
require 'xcodeproj'
require 'pp'
require 'fileutils'
require 'erb'

module Bagen
  module Generator
    class TemplatingContext
      include Bagen::Helpers

      def initialize(args, options)
        @template = args[0]
        @project = args[1]
        @configuration = args[2]
        @target = args[3]
        @project_dir = Pathname.new(options.project_dir)
        @args = args
        @options = options
      end

      def include(template_path)
        template_path += '.xcconfig.erb' unless template_path.match?(/xcconfig\.erb$/)
        template = ERB.new File.read(template_path)
        Dir.chdir File.dirname(template_path) do
          template.result(get_binding)
        end
      end

      def get_binding # this is only a helper method to access the objects binding method
        binding
      end
    end

    extend Bagen::Helpers

    def self.templates_dir
      self_path = Pathname.new(__FILE__).realpath
      File.expand_path('../../../templates', self_path)
    end

    def self.generate(args, options)
      template = args[0]
      output = options.output
      template_path = File.join(templates_dir, template + '.xcconfig.erb')
      die "required template does not exists at #{template_path.yellow}" unless File.exist? template_path

      header = <<-XEND.gsub(/^ {6}/, '')
      // A GENERATED FILE by bagen utility
      // more info: https://github.com/binaryage/badev
      //
      //   !!! DO NOT EDIT IT BY HAND !!!
      //

      XEND

      result = nil
      context = TemplatingContext.new(args, options)
      template = ERB.new File.read(template_path)
      Dir.chdir File.dirname(template_path) do
        result = template.result(context.get_binding)
      end

      # final cleanup
      lines = result.split("\n")
      lines.map!(&:strip) # strip lines
      lines.reject! { |line| line =~ /^\/\/([^\/]|$)/ } # remove simple comments
      lines.reject!(&:empty?) # remove empty lines
      lines.map! { |line| line.gsub(/^\/\/\/(.*)$/, '//\1') } # replace tripple comments with normal comments

      contents = header + lines.join("\n")

      if output
        File.open(output, 'w') { |file| file.write(contents) }
      else
        puts contents
      end
    end
  end
end
