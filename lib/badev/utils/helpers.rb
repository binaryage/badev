# frozen_string_literal: true

require 'open3'

module Badev
  module Helpers
    @@indent = ''
    @@dry_run = false

    module_function

    def reset_indent!
      @@indent = ''
    end

    def indent(how = '  ')
      previous_indent = @@indent
      @@indent += how
      yield()
      @@indent = previous_indent
    end

    def puts(thing)
      Kernel.puts @@indent + thing.to_s
    end

    def print_indented(text)
      text.to_s.each_line do |line|
        puts line
      end
    end

    def dry_run?
      @@dry_run
    end

    def run_dry!
      @@dry_run = true
    end

    def sys(cmd, soft = false, silenced = false)
      marker = '! '
      marker = '? ' if dry_run?
      puts "#{marker.yellow}#{cmd.yellow}"

      output = ''
      unless dry_run?
        status = nil
        output = Open3.popen2e(cmd) do |_stdin, out_and_err, wait_thr|
          status = wait_thr.value
          out_and_err.read
        end

        indent do
          print_indented(output) unless silenced
        end

        die("failed with code #{status.exitstatus}", status.exitstatus) if !status.success? && !soft
      end

      output
    end

    def die(msg, exitstatus = 1)
      puts msg.red
      exit exitstatus
    end

    def shellescape(str)
      # An empty argument will be skipped, so return empty quotes.
      return "''" if str.nil?

      str = str.to_s unless str.is_a?(String) && str.respond_to?('to_s', true)
      return "''" if str.empty?

      str = str.dup

      # Treat multibyte characters as is.  It is caller's responsibility
      # to encode the string in the right encoding for the shell
      # environment.
      str.gsub!(/([^A-Za-z0-9_\-.,:\/@\n])/, '\\\\\\1')

      # A LF cannot be escaped with a backslash because a backslash + LF
      # combo is regarded as line continuation and simply ignored.
      str.gsub!(/\n/, "'\n'")

      str
    end

    def revision
      `git rev-parse HEAD`.strip
    end

    def short_revision
      revision[0...7]
    end

    def release_version_from_filename(path, ext = '.txt')
      # path == /Users/darwin/code/totalfinder/payloads/TotalFinder-0.7.1.txt
      p = File.basename(path, ext).split('-')[1]
      path = p.split('.')
      path << '0' while path.size < 3
      x = (path[0] || '0').to_i
      y = (path[1] || '0').to_i
      z = (path[2] || '0').to_i
      x * 1_000_000 + y * 1000 + z
    end

    def read_dwarfs_base_dir
      if File.exist? 'totalfinder/.dwarfs'
        return File.expand_path(File.read('totalfinder/.dwarfs').strip) # HACK: for TotalFinder
      end

      unless File.exist? '.dwarfs'
        puts ".dwarfs file is not present in #{Dir.pwd.blue}".red
        return nil
      end
      File.expand_path(File.read('.dwarfs').strip)
    end
  end
end
