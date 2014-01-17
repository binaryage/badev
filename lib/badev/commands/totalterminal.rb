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

    REMOVE_DEV_TOTALTERMINAL_OSAX_CMD = 'rm -rf ~/Library/ScriptingAdditions/TotalTerminal.osax'
    REMOVE_DEV_TOTALTERMINAL_APP_CMD = 'rm -rf ~/Applications/TotalTerminal.app'

    REMOVE_RETAIL_TOTALTERMINAL_OSAX_CMD = 'sudo rm -rf /Library/ScriptingAdditions/TotalTerminal.osax'
    REMOVE_RETAIL_TOTALTERMINAL_APP_CMD = 'sudo rm -rf /Applications/TotalTerminal.app'
        
    def self.launch_terminal(options)
      sys(ACTIVATE_TERMINAL_CMD)
    end

    def self.quit_terminal(options)
      sys(QUIT_TERMNAL_CMD)
    end

    def self.kill_terminal(options)
      sys(KILL_TERMINAL_CMD)
    end

    def self.restart_terminal(options)
      sys(QUIT_TERMINAL_CMD)
      sys("sleep 1")
      sys(LAUNCH_TERMINAL_CMD)
    end

    def self.quit_totalterminal(options)
      sys(QUIT_TERMINAL_CMD)
      sys(QUIT_TOTALTERMINAL_CMD)
    end

    def self.restart_totalterminal(options)
      sys(QUIT_TERMINAL_CMD)
      sys("sleep 1")
      sys(INJECT_TOTALTERMINAL_CMD)
    end

    def self.inject_totalterminal(options)
      sys(INJECT_TOTALTERMINAL_CMD)
    end

    def self.open_totalterminal(options)
      sys(OPEN_TOTALTERMINAL_CMD)
    end

    def self.crash_totalterminal(options)
      sys(CRASH_TOTALTERMINAL_CMD)
    end

    def self.remove_dev(options)
      sys(REMOVE_DEV_TOTALTERMINAL_OSAX_CMD)
      sys(REMOVE_DEV_TOTALTERMINAL_APP_CMD)
    end

    def self.remove_retail(options)
      sys(REMOVE_RETAIL_TOTALTERMINAL_OSAX_CMD)
      sys(REMOVE_RETAIL_TOTALTERMINAL_APP_CMD)
    end

  end
end
