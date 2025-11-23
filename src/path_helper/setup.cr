module PathHelper
  module Setup
    ENV_VARS = {
      "C_INCLUDE_PATH"              => "-c",
      "DYLD_FALLBACK_FRAMEWORK_PATH" => "--dyld-fram",
      "DYLD_FALLBACK_LIBRARY_PATH"  => "--dyld-lib",
      "MANPATH"                     => "-m",
      "PKG_CONFIG_PATH"             => "-pc",
      "PATH"                        => "-p",
    }

    def self.setup!(options : Hash(Symbol, String | Bool | Nil)) : Bool
      search_order = Helpers.determine_search_order(options)
      permission_errors = [] of String
      quiet = options[:quiet]? == true
      dry_run = options[:dry_run]? == true

      ENV_VARS.each do |var, _|
        section = Helpers.create_section(var)

        # Filter to only segments in search order
        section.directories.reject! { |segment, _| !search_order.includes?(segment) }
        section.files.reject! { |segment, _| !search_order.includes?(segment) }

        # Create directories
        section.directories.each do |_, path|
          if File.exists?(path)
            STDERR.puts "#{Colors::YELLOW}#{path} already exists, skipping#{Colors::NORMAL}" unless quiet
            next
          end
          begin
            unless dry_run
              Dir.mkdir_p(path)
            end
            puts "#{Colors::GREEN}Created #{path}#{Colors::NORMAL}" unless quiet
          rescue ex : File::AccessDeniedError
            STDERR.puts "#{Colors::RED}Rescuing permission errors for #{path}#{Colors::NORMAL}"
            permission_errors << path
          end
        end

        # Create files
        section.files.each do |_, path|
          if File.exists?(path)
            STDERR.puts "#{Colors::YELLOW}#{path} already exists, skipping#{Colors::NORMAL}" unless quiet
            next
          end
          begin
            unless dry_run
              File.touch(path)
            end
            puts "#{Colors::GREEN}Created #{path}#{Colors::NORMAL}" unless quiet
          rescue ex : File::AccessDeniedError
            STDERR.puts "#{Colors::RED}Rescuing permission errors for #{path}#{Colors::NORMAL}"
            permission_errors << path
          end
        end
      end

      unless permission_errors.empty?
        STDERR.puts "Your account does not have permissions for:"
        permission_errors.each do |path|
          STDERR.puts "- #{path}"
        end
        STDERR.puts <<-WARNING
          Consider whether you need to install these.
          For example are they needed system wide? If not, use the --no-etc switch.
          Otherwise, try again with sudo or another account.
        WARNING
        return false
      end

      script_path = Process.executable_path || "path_helper"
      unless quiet
        env_exports = ENV_VARS.map { |var, switch| "export #{var}=$(#{script_path} #{switch})" }.join("\n  ")
        puts <<-SHENV


        # Put this in your ~/.bashrc or your ~/.zshenv
        if [ -x #{script_path} ]; then
          #{env_exports}
        fi
        SHENV
      end

      true
    end
  end
end
