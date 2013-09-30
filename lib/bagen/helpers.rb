module Bagen
  module Helpers

    extend self

    def sys(cmd)
      puts ">#{cmd.yellow}"
      unless system(cmd) then
        puts "failed".red
        exit 1
      end
    end

    def die(msg)
      puts msg.red
      exit 2
    end
  end
end