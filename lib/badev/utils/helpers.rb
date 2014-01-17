module Badev
  module Helpers

    extend self
    
    def indent(how="  ")
      old_indent = $indent
      $indent += how
      yield()
      $indent = old_indent
    end
    
    def puts(x)
      Kernel.puts $indent+x
    end

    def sys(cmd, soft=false)
      marker = "! "
      marker = "? " if $dry_run
      puts "#{marker.yellow}#{cmd.yellow}"
      unless $dry_run then
        unless system(cmd) then
          die "failed" unless soft
        end
      end
    end

    def die(msg)
      puts msg.red
      exit ($?.exitstatus or 1)
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