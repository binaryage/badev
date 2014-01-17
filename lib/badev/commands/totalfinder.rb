INJECT_TOTALFINDER_CMD = 'osascript -e "tell application \"Finder\" to «event BATFinit»"'
CRASH_TOTALFINDER_CMD = 'osascript -e "tell application \"Finder\" to «event BAHCcrsh»"'
OPEN_TOTALFINDER_CMD = 'open ~/Applications/TotalFinder.app'
QUIT_TOTALFINDER_CMD = 'osascript -e "tell app \"TotalFinder\" to quit"'
ACTIVATE_FINDER_CMD = 'osascript -e "tell application \"Finder\" to activate"'
QUIT_FINDER_CMD = 'osascript -e "tell application \"Finder\" to quit"'
KILL_FINDER_CMD = 'killall Finder'
LAUNCH_FINDER_CMD = 'open Finder'

REMOVE_DEV_TOTALFINDER_OSAX_CMD = 'rm -rf ~/Library/ScriptingAdditions/TotalFinder.osax'
REMOVE_DEV_TOTALFINDER_APP_CMD = 'rm -rf ~/Applications/TotalFinder.app'

REMOVE_RETAIL_TOTALFINDER_OSAX_CMD = 'sudo rm -rf /Library/ScriptingAdditions/TotalFinder.osax'
REMOVE_RETAIL_TOTALFINDER_APP_CMD = 'sudo rm -rf /Applications/TotalFinder.app'

module Badev
  module TotalFinder

    extend Badev::Helpers
    
    def self.launch_finder(options)
      sys(ACTIVATE_FINDER_CMD)
    end

    def self.quit_finder(options)
      sys(QUIT_FINDER_CMD)
    end

    def self.kill_finder(options)
      sys(KILL_FINDER_CMD)
    end

    def self.restart_finder(options)
      sys(QUIT_FINDER_CMD)
      sys("sleep 1")
      sys(LAUNCH_FINDER_CMD)
    end

    def self.quit_totalfinder(options)
      sys(QUIT_FINDER_CMD)
      sys(QUIT_TOTALFINDER_CMD)
    end

    def self.restart_totalfinder(options)
      sys(QUIT_FINDER_CMD)
      sys("sleep 1")
      sys(INJECT_TOTALFINDER_CMD)
    end

    def self.inject_totalfinder(options)
      sys(INJECT_TOTALFINDER_CMD)
    end

    def self.open_totalfinder(options)
      sys(OPEN_TOTALFINDER_CMD)
    end

    def self.crash_totalfinder(options)
      sys(CRASH_TOTALFINDER_CMD)
    end

    def self.remove_dev(options)
      sys(REMOVE_DEV_TOTALFINDER_OSAX_CMD)
      sys(REMOVE_DEV_TOTALFINDER_APP_CMD)
    end

    def self.remove_retail(options)
      sys(REMOVE_RETAIL_TOTALFINDER_OSAX_CMD)
      sys(REMOVE_RETAIL_TOTALFINDER_APP_CMD)
    end

  end
end
