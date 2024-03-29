# frozen_string_literal: true

module Badev
  module Osax
    extend Badev::Helpers

    AUTHORIZE_SEND_CMD = 'sudo security authorizationdb write com.apple.OpenScripting.additions.send allow'
    DEAUTHORIZE_SEND_CMD = 'sudo security authorizationdb remove com.apple.OpenScripting.additions.send'

    def self.authorize_send(_options)
      sys(AUTHORIZE_SEND_CMD)
    end

    def self.deauthorize_send(_options)
      sys(DEAUTHORIZE_SEND_CMD)
    end
  end
end
