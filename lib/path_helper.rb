require 'pathname'

module PathHelper

  HOME = Pathname(ENV["HOME"])

  BASE_PATHS = [
    HOME.join("Library/Paths"),
    HOME.join(".config/paths"),
    Pathname("/etc"),
  ]

  DEFAULT_PATHS = ["paths.d","paths"]

  class CLI

    ENV_NAMES = {
      :ci         =>  "C_INCLUDE_PATH",
      :dyld_fram  =>  "DYLD_FALLBACK_FRAMEWORK_PATH",
      :dyld_lib   =>  "DYLD_FALLBACK_LIBRARY_PATH",
      :man        =>  "MANPATH",
      :path       =>  "PATH"
    }


    # @param [Hash] options The parsed CLI options.
    def initialize options
      @options = options
      @base_paths = BASE_PATHS.dup
      @context_paths = DEFAULT_PATHS.dup
      @tree = {}
      @current_path = options[:path] || ""

      @key = ENV_NAMES.keys.find{|x| @options.has_key? x } || :path
      send "init_#{@key}"
      @entries = Entries.new @additional_path
    end


    def base_init item
      @base_paths.each {|base|
        @context_paths.each{|x|
          @tree[ base.join item.(x) ] = []
        }
      }
    end


    def init_ci
      base_init ->(x){ "include_#{x}" }
      options_or_try_env :ci
    end


    def init_dyld_fram
      base_init ->(x){ "dyld_framework_#{x}" }
      options_or_try_env :dyld_fram
    end

    def init_dyld_lib
      base_init ->(x){ "dyld_library_#{x}" }
      options_or_try_env :dyld_lib
    end

    def init_path
      base_init ->(x){ x }
      options_or_try_env :path
    end


    def init_man
      base_init ->(x){ "man#{x}" }
      options_or_try_env :man do
        @current_path = ENV["MANPATH"] || `man -w`
      end
    end


    def options_or_try_env name
      if @options[name].respond_to? :split
        @additional_path = @options[name]
      end
      if block_given?
        yield
      else
        @current_path = ENV[ ENV_NAMES[name] ]
      end
    end


    def output_debug_lines lines
      warn lines.map{|x| "\t#{x}\n" }.join if @options[:debug]
    end


    # Helper that reads lines from a file and adds them to Entries
    # @param [Pathname] File to read.
    def read_file pn
      pn.readlines.map(&:chomp)
        .each do |line|
          @entries.add line, pn
        end
    end


    def paths
      @tree.keys.each do |leaf|
        if leaf.exist?
          if leaf.directory?
            leaf.children
                .select{|pn|
                  pn.file? and not pn.basename.to_s =~ /^\./
                }.sort_by{|pn| pn.basename }
                .each do |pn|
                  @tree[leaf] << pn
                  read_file pn
                end
          else
            @tree[leaf] << leaf
            read_file leaf
          end
        end
      end

      if @options[:verbose]
        warn @entries.debug
        warn "Current:\n#{@current_path}"
        warn "\n\n"
      end
      final = @entries.ready

      if @options[:verbose]
        warn <<~STR
        If you expected items you'd inserted in the path manually to
        show up earlier then either clear the path before running this
        and reinsert or add paths via:
          (~/Library/Paths|~/config)/#{DEFAULT_PATHS.first}
          (~/Library/Paths|~/config)/#{DEFAULT_PATHS.last}/*)\n\n
        STR
      end

      final
    end

  end


  # Transforms lines into a path.
  class Entries

    class << self
      # Basically, replace tildes and clean up the path.
      def path_format xs
        xs.compact  # no nils
          .reject(&:empty?)
          .uniq      # no repetitions, later loses
          .map{|x| x.sub /\~/, ENV["HOME"]}
          .join(":")
      end
    end


    # @param [Hash,nil] additional Items to append to the path.
    def initialize additional=nil
      @entries = {} 
      @additional = if additional
        additional.respond_to?(:compact) ? additional : [additional]
      else
        nil
      end
    end


    # @param [String] entry The line read from the file that will become part of the path.
    # @param [Pathname] The file.
    def add( entry, origin )
      if @entries.has_key? entry
        @entries[entry] << origin
      else
        @entries[entry] = [origin]
      end
    end


    # Make the entries ready to format into a path
    def ready
      @interim = @entries.map{|entry,_| entry }
      if @additional
        @interim += @additional
      end
      @interim.freeze
      path_format
    end

  
    def path_format
      self.class.path_format @interim
    end

    def tilde pn
      pn.to_s.sub(HOME.to_s, "~")
    end


    def debug
      output = []
      output.push sprintf "\n\n%40s | %-40s | %-40s\n", "Path", "Found in", "Ignored duplicate"
      output.push sprintf "%40s | %-40s | %-40s\n", "----", "--------", "-----------------"
      @entries.each do |entry,pathnames|
        if pathnames.size >= 2
          pns = pathnames.each
          output.push sprintf "%40s | %-40s | \n", entry, tilde(pns.next), ""
          loop do
            output.push sprintf "%40s | %-40s |   %-20s\n", "", tilde(pns.next), "✗"
          end
          
        else
          output.push sprintf "%40s | %-40s | \n", entry, tilde(pathnames.first), ""
        end
      end
      output << "\n\n"
      if @additional
        output << "Additional via commandline: \n"
        output << path_format( @additional)
        output << "\n\n"
      end
      output.join
    end
  end
end

