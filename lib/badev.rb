require 'badev/version'

module Badev

  USER_AGENT = "badev/#{Badev::VERSION} (#{RUBY_PLATFORM}) ruby/#{RUBY_VERSION}"

  BASE_DIR = File.expand_path(File.join(File.dirname(__FILE__), '..'))
  BIN_DIR = File.join(BASE_DIR, 'bin')
  TOOLS_DIR = File.join(BIN_DIR, 'tools')
  TEMPLATES_DIR = File.join(BASE_DIR, 'templates')
  CONFIGS_DIR = File.join(BASE_DIR, 'configs')

end
