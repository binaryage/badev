module Badev
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

    def shellescape(str)
      # An empty argument will be skipped, so return empty quotes.
      return "''" if str.empty?

      str = str.dup

      # Treat multibyte characters as is.  It is caller's responsibility
      # to encode the string in the right encoding for the shell
      # environment.
      str.gsub!(/([^A-Za-z0-9_\-.,:\/@\n])/, "\\\\\\1")

      # A LF cannot be escaped with a backslash because a backslash + LF
      # combo is regarded as line continuation and simply ignored.
      str.gsub!(/\n/, "'\n'")

      return str
    end
  end
end