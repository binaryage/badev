require 'commander/import'
require 'colored'
require 'fileutils'
require 'pathname'
require "baproj/version"

module Baproj

  USER_AGENT = "baproj/#{Baproj::VERSION} (#{RUBY_PLATFORM}) ruby/#{RUBY_VERSION}"

  autoload :CLI,        'baproj/cli'
  autoload :Helpers,    'baproj/helpers'
  autoload :Project,    'baproj/project'

end