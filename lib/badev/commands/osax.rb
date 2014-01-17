module Badev
  module Osax
    extend Badev::Helpers
    
    AUTHORIZE_SEND_CMD = 'sudo security authorizationdb write com.apple.OpenScripting.additions.send allow'
    DEAUTHORIZE_SEND_CMD = 'sudo security authorizationdb write com.apple.OpenScripting.additions.send remove'
    
    def self.authorize_send(options)
      sys(AUTHORIZE_SEND_CMD)
    end

    def self.deauthorize_send(options)
      sys(DEAUTHORIZE_SEND_CMD)
    end
    
  end
end
