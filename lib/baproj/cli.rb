module Baproj
  class CLI

    def self.start(*args)
      program :name, 'baproj'
      program :version, Baproj::VERSION
      program :description, 'A helper tool for development in BinaryAge'
      program :help_formatter, :compact

      command :create do |c|
        c.description = 'creates a baproj heorarchy beginning at the root directory'
        c.syntax = 'baproj create [-f|--force] --path PATH --name NAME --prefix PREFIX'
        c.option '--path PATH', String, 'Specify the path'
        c.option '--name NAME', String, 'Specify the project name'
        c.option '--prefix PREFIX', String, 'Specify the class prefix'
        c.option '-f', '--force', 'Overwrite existing file at path'
        c.action do |args, options|
          options.default :path => Pathname.pwd + ".baproj"
          # Create a new Baproj::Project at :path
          if File.exist?(options.path)
            unless File.read(options.path).empty? && options.force
              raise "[Baproj] Unable to create project. `#{options.path}` already exists"
            end
          end

          proj = Baproj::Project.open(options.path)
          proj.name = options.name
          proj.prefix = options.prefix
          proj.save
        end
      end
    end

  end
end

