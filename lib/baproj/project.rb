require 'pathname'
require 'fileutils'

module Baproj
  class Project

    include Baproj::Helpers

    # path(Pathname) of the .baproj file
    attr_reader :path

    # Hash containing the key/value pairs defined
    attr_accessor :ba_attributes

    # Currently well supported settings names
    #
    # => name
    # => prefix
    # => tag_prefix
    # => prefix_excluded_files
    DEFAULT_ATTRIBUTES = {
      :BA_PROJECT_NAME => File.dirname(Dir.pwd)
      :BA_CLASS_PREFIX => ""
      :BA_TAG_PREFIX => ""
      :BA_CLASS_PREFIX_EXCLUDE => []
    }

    def initialize(_path=".baproj", attrs={})
      @path = Pathname.new(_path).expand_path
      @ba_attributes = DEFAULT_ATTRIBUTES.dup
      set_default_attributes(attrs)
      initialize_from_file
    end

    def self.open(_path)
      _path = Pathname.new(_path).expand_path
      _path = _path + ".baproj" if _path.directory?

      unless _path.exist?
        raise "[Baproj] Unable to open `#{_path}` because it doesn't exist."
      end

      new(_path)
    end

    def expanded_value(val)
      return nil if val.nil?
      val.gsub!(/\$\(BA_PROJECT_DIR\)/, "#{@path.dirname}")
    # some other pre-defined keys
      # substitute project defined settings
      val
    end

    def split_value(val)
      return "" if val.nil?
      values = []
      if val =~ /".*?"/
        val.gsub!(/"([^"]*)"/) do |m|
          values << expanded_value("#{$1}")
          ""
        end
      end
      remaining = val.split(" ").map! { |item| expanded_value(item) }
      values.concat(remaining)
      values.compact.sort.uniq
      return values[0] if values.count == 1
      values
    end
    
    def set_default_attributes(attrs)
      @ba_attributes.merge!(attrs.to_hash) if attrs.respond_to?(:to_hash)
    end

    def initialize_from_file
      return unless @path.readable?
      contents = @path.read
      contents.each_line do |line|
        line.match(/^\s*(\w+)\s*=\s*(.+?)$/) do |m|
          key = m[1]
          value = m[2]
          next m if key.nil? or key.empty?
          next m if value.nil? or value.empty?
          #@ba_attributes[key] = split_value(value)
          @ba_attributes[key] = expanded_value(value)
        end
      end
    end

    alias :read :initialize_from_file

    def ==(other)
      other.respond_to?(:to_hash) && to_hash == other.to_hash
    end

    def to_s
      "#<#{self.class}> path:`#{path}`\n" + to_hash.inspect
    end

    alias :inspect :to_s

    def to_hash
      hash = @ba_attributes.dup
      hash['path'] = path.to_s
      hash
    end

    def to_baproj
      lines = []
      ba_attributes.each do |k,v|
        value = nil
        if v.is_a? Array
          value = v.join(" ")
        elsif v.respond_to?("to_s", true)
          value = v.to_s
        else
          value = v
        end
        next if value.nil?
        lines << "#{k} = #{value}"
      end
      lines.join("\n")
    end

    def dup
      Baproj::Project.new(@path.dup, @ba_attributes.dup)
    end

    def save(save_path=@path)
      File.open(save_path, "w") { |f| f.write(to_baproj) }
    end

    def include_dir
      @path.dirname + "headers"
    end

    def relative_include_dir(from_path)
      include_dir.relative_path_from(Pathname.new(from_path))
    end

    def [](key);                              @ba_attributes[key];                                        end;
    def name;                                 @ba_attributes["BA_PROJECT_NAME"];                          end;
    def prefix;                               @ba_attributes["BA_CLASS_PREFIX"];                          end;
    def tag_prefix;                           @ba_attributes["BA_TAG_PREFIX"];                            end;
    def prefix_excluded_files
      files = @ba_attributes["BA_CLASS_PREFIX_EXCLUDE"]
      return [] unless files
      files
    end

    def []=(key, value);                      @ba_attributes[key] = value;                                end;
    def name=(value);                         @ba_attributes["BA_PROJECT_NAME"] = value;                  end;
    def prefix=(value);                       @ba_attributes["BA_CLASS_PREFIX"] = value;                  end;
    def tag_prefix=(value);                   @ba_attributes["BA_TAG_PREFIX"] = value;                    end;
    def prefix_excluded_files=(value);        @ba_attributes["BA_CLASS_PREFIX_EXCLUDE"] = value;          end;

  end
end