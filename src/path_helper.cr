require "option_parser"

require "./path_helper/version"
require "./path_helper/colors"
require "./path_helper/helpers"
require "./path_helper/cli"
require "./path_helper/debug"
require "./path_helper/setup"

module PathHelper
  def self.run
    options = Hash(Symbol, String | Bool | Nil).new

    parser = OptionParser.new do |opts|
      opts.banner = "Usage: path_helper [options]"

      opts.on("-p [PATH]", "--path [PATH]",
        "To get a completely fresh PATH pass an empty string or nothing at all (the default).\n" \
        "  To append something to the generated path pass the current path, or a path you wish appended."
      ) do |path|
        options[:name] = "PATH"
        options[:current_path] = path.empty? ? nil : path
      end

      opts.on("-m [MANPATH]", "--man [MANPATH]",
        "Run for man pages but perhaps read `man manpages` first\n" \
        "  See `path' instructions for argument options."
      ) do |path|
        options[:name] = "MANPATH"
        options[:current_path] = path.empty? ? nil : path
      end

      opts.on("-f [DYLD]", "--dyld-fram [DYLD]",
        "DYLD_FALLBACK_FRAMEWORK_PATH env var\n" \
        "  See `path' instructions for argument options."
      ) do |path|
        options[:name] = "DYLD_FALLBACK_FRAMEWORK_PATH"
        options[:current_path] = path.empty? ? nil : path
      end

      opts.on("-l [DYLD]", "--dyld-lib [DYLD]",
        "DYLD_FALLBACK_LIBRARY_PATH env var\n" \
        "  See `path' instructions for argument options."
      ) do |path|
        options[:name] = "DYLD_FALLBACK_LIBRARY_PATH"
        options[:current_path] = path.empty? ? nil : path
      end

      opts.on("-c [C_INCLUDE]", "--c-include [C_INCLUDE]",
        "C_INCLUDE_PATH env var\n" \
        "  See `path' instructions for argument options."
      ) do |path|
        options[:name] = "C_INCLUDE_PATH"
        options[:current_path] = path.empty? ? nil : path
      end

      opts.on("--pc [PKG_CONFIG_PATH]",
        "PKG_CONFIG_PATH env var\n" \
        "  See `path' instructions for argument options."
      ) do |path|
        options[:name] = "PKG_CONFIG_PATH"
        options[:current_path] = path.empty? ? nil : path
      end

      opts.on("-q", "--quiet", "Quiet, no output") do
        options[:quiet] = true
      end

      opts.on("-d", "--debug", "Debug mode, even more output") do
        options[:debug] = true
      end

      opts.on("--setup",
        "Set up directory structure, add specific switches\n" \
        "  (see `--etc` `--lib` `--config`)\n" \
        "  if specific setups required.\n" \
        "  Else --setup own its own will do all of them."
      ) do
        options[:setup] = true
      end

      opts.on("--dry-run",
        "Use in conjuction with --setup to see what would happen if you ran it."
      ) do
        options[:dry_run] = true
      end

      opts.on("--etc", "Include /etc paths (default: included)") do
        options[:etc] = true
      end

      opts.on("--no-etc", "Exclude /etc paths") do
        options[:etc] = false
      end

      opts.on("--lib", "Include ~/Library/Paths (default: on macOS)") do
        options[:lib] = true
      end

      opts.on("--no-lib", "Exclude ~/Library/Paths") do
        options[:lib] = false
      end

      opts.on("--config", "Include ~/.config/paths (default: on Linux)") do
        options[:config] = true
      end

      opts.on("--no-config", "Exclude ~/.config/paths") do
        options[:config] = false
      end

      opts.on("--version", "Print version") do
        STDERR.puts VERSION
        exit 0
      end

      opts.on("-h", "--help", "Show this message") do
        STDERR.puts opts
        exit 0
      end
    end

    # Show help if no arguments
    if ARGV.empty?
      STDERR.puts parser
      exit 1
    end

    parser.parse

    # Check for DEBUG environment variable
    if ENV["DEBUG"]?
      options[:debug] = true
    end

    if options[:debug]?
      options[:verbose] = true
    end

    # Run setup or normal path building
    if options[:setup]?
      status_code = Setup.setup!(options) ? 0 : 1
      exit status_code
    else
      begin
        helper = CLI.new(options)
        if options[:debug]?
          env_var = helper.run
          debugger = Debug.new(helper)
          print debugger.render
          puts "\n\nEnv var:\n"
          print env_var + "\n\n"
        else
          print helper.run
        end
      rescue ex : Error
        STDERR.puts ex.message
        STDERR.puts "See --help for available options."
        exit 1
      end
    end

    exit 0
  end
end

PathHelper.run
