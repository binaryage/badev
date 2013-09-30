require "bagen/version"

module Bagen

  USER_AGENT = "bagen/#{Bagen::VERSION} (#{RUBY_PLATFORM}) ruby/#{RUBY_VERSION}"

  def self.user_agent
    @@user_agent ||= USER_AGENT
  end

  def self.user_agent=(agent)
    @@user_agent = agent
  end

end
