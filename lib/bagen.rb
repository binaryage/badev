# frozen_string_literal: true

require 'bagen/version'

module Bagen
  USER_AGENT = "bagen/#{Bagen::VERSION} (#{RUBY_PLATFORM}) ruby/#{RUBY_VERSION}".freeze
end
