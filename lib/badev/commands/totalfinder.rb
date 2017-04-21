module Badev
  module TotalFinder
    extend Badev::Helpers

    INJECT_TOTALFINDER_CMD = 'osascript -e "tell application \"Finder\" to «event BATFinit»"'
    CRASH_TOTALFINDER_CMD = 'osascript -e "tell application \"Finder\" to «event BAHCcrsh»"'
    OPEN_TOTALFINDER_CMD = 'open ~/Applications/TotalFinder.app'
    QUIT_TOTALFINDER_CMD = 'osascript -e "tell app \"TotalFinder\" to quit"'
    ACTIVATE_FINDER_CMD = 'osascript -e "tell application \"Finder\" to activate"'
    QUIT_FINDER_CMD = 'osascript -e "tell application \"Finder\" to quit"'
    KILL_FINDER_CMD = 'killall Finder'
    LAUNCH_FINDER_CMD = 'open Finder'

    REMOVE_DEV_OSAX_CMD = 'rm -rf ~/Library/ScriptingAdditions/TotalFinder*.osax'
    REMOVE_DEV_APP_CMD = 'rm -rf ~/Applications/TotalFinder.app'

    REMOVE_REL_OSAX_CMD = 'sudo rm -rf /Library/ScriptingAdditions/TotalFinder.osax'
    REMOVE_REL_APP_CMD = 'sudo rm -rf /Applications/TotalFinder.app'

    def self.launch_finder(_options)
      sys(ACTIVATE_FINDER_CMD)
    end

    def self.quit_finder(_options)
      sys(QUIT_FINDER_CMD)
    end

    def self.kill_finder(_options)
      sys(KILL_FINDER_CMD)
    end

    def self.restart_finder(_options)
      sys(QUIT_FINDER_CMD)
      sys('sleep 1')
      sys(LAUNCH_FINDER_CMD)
    end

    def self.quit_totalfinder(_options)
      sys(QUIT_FINDER_CMD)
      sys(QUIT_TOTALFINDER_CMD)
    end

    def self.restart_totalfinder(_options)
      sys(QUIT_FINDER_CMD)
      sys('sleep 1')
      sys(INJECT_TOTALFINDER_CMD)
    end

    def self.inject_totalfinder(_options)
      sys(INJECT_TOTALFINDER_CMD)
    end

    def self.open_totalfinder(_options)
      sys(OPEN_TOTALFINDER_CMD)
    end

    def self.crash_totalfinder(_options)
      sys(CRASH_TOTALFINDER_CMD)
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
