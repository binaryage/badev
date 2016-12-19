module Badev
  module TotalTerminal
    extend Badev::Helpers

    INJECT_TOTALTERMINAL_CMD = 'osascript -e "tell application \"Terminal\" to «event BATTinit»"'
    CRASH_TOTALTERMINAL_CMD = 'osascript -e "tell application \"Terminal\" to «event BAHCcrsh»"'
    OPEN_TOTALTERMINAL_CMD = 'open ~/Applications/TotalTerminal.app'
    QUIT_TOTALTERMINAL_CMD = 'osascript -e "tell app \"TotalTerminal\" to quit"'
    ACTIVATE_TERMINAL_CMD = 'osascript -e "tell application \"Terminal\" to activate"'
    QUIT_TERMINAL_CMD = 'osascript -e "tell application \"Terminal\" to quit"'
    KILL_TERMINAL_CMD = 'killall Terminal'
    LAUNCH_TERMINAL_CMD = 'open Terminal'

    REMOVE_DEV_OSAX_CMD = 'rm -rf ~/Library/ScriptingAdditions/TotalTerminal.osax'
    REMOVE_DEV_APP_CMD = 'rm -rf ~/Applications/TotalTerminal.app'

    REMOVE_REL_OSAX_CMD = 'sudo rm -rf /Library/ScriptingAdditions/TotalTerminal.osax'
    REMOVE_REL_APP_CMD = 'sudo rm -rf /Applications/TotalTerminal.app'

    def self.launch_terminal(_options)
      sys(ACTIVATE_TERMINAL_CMD)
    end

    def self.quit_terminal(_options)
      sys(QUIT_TERMNAL_CMD)
    end

    def self.kill_terminal(_options)
      sys(KILL_TERMINAL_CMD)
    end

    def self.restart_terminal(_options)
      sys(QUIT_TERMINAL_CMD)
      sys('sleep 1')
      sys(LAUNCH_TERMINAL_CMD)
    end

    def self.quit_totalterminal(_options)
      sys(QUIT_TERMINAL_CMD)
      sys(QUIT_TOTALTERMINAL_CMD)
    end

    def self.restart_totalterminal(_options)
      sys(QUIT_TERMINAL_CMD)
      sys('sleep 1')
      sys(INJECT_TOTALTERMINAL_CMD)
    end

    def self.inject_totalterminal(_options)
      sys(INJECT_TOTALTERMINAL_CMD)
    end

    def self.open_totalterminal(_options)
      sys(OPEN_TOTALTERMINAL_CMD)
    end

    def self.crash_totalterminal(_options)
      sys(CRASH_TOTALTERMINAL_CMD)
    end

    def self.remove_dev(_options)
      sys(REMOVE_DEV_OSAX_CMD)
      sys(REMOVE_DEV_APP_CMD)
    end

    def self.remove_retail(_options)
      sys(REMOVE_REL_OSAX_CMD)
      sys(REMOVE_REL_APP_CMD)
    end

  end
end
