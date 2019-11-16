# frozen_string_literal: true

module Bagen
  module Helpers
    module_function

    def sys(cmd)
      puts ">#{cmd.yellow}"
      return if system(cmd)

      puts 'failed'.red
      exit 1
    end

    def die(msg)
      puts msg.red
      exit 2
    end
  end
end
