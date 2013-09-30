require "pathname"
require 'xcodeproj'
require 'pp'
require 'fileutils'
require 'erb'

module Bagen
  module Generator

    class TemplatingContext

      include Bagen::Helpers

      def initialize(args)
        @template = args[0]
        @project = args[1]
        @configuration = args[2]
        @target = args[3]
        @args = args
      end

      def include(template_path)
        template_path += ".xcconfig.erb" unless template_path =~ /xcconfig\.erb$/
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
      File.expand_path("../../../templates", self_path)
    end

    def self.generate(args)
      template = args[0]
      template_path = File.join(templates_dir(), template + ".xcconfig.erb")
      die "required template does not exists at #{template_path.yellow}" unless File.exists? template_path

      header = <<-XEND.gsub(/^ {6}/, '')
      // A GENERATED FILE by bagen utility
      // more info: https://github.com/binaryage/badev
      //
      //   !!! DO NOT EDIT IT BY HAND !!!
      //

      XEND

      result = nil
      context = TemplatingContext.new args
      template = ERB.new File.read(template_path)
      Dir.chdir File.dirname(template_path) do
        result = template.result(context.get_binding)
      end

      # final cleanup
      lines = result.split("\n")
      lines.map! { |line| line.strip } # strip lines
      lines.reject! { |line| line=~ /^\/\/([^\/]|$)/ } # remove simple comments
      lines.reject! { |line| line.empty? } # remove empty lines
      lines.map! { |line| line.gsub(/^\/\/\/(.*)$/, '//\1') } # replace tripple comments with normal comments

      puts header+lines.join("\n")
    end

  end
end