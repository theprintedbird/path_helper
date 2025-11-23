module PathHelper
  class CLI
    getter section : Section
    getter options : Hash(Symbol, String | Bool | Nil)

    def initialize(@options : Hash(Symbol, String | Bool | Nil))
      unless @options.has_key?(:name)
        raise Error.new("You must declare the kind of path you wish to build e.g. --manpath or -m if you want MANPATH built")
      end

      name = @options[:name].as(String)
      # Use current_path if provided, otherwise fall back to ENV
      @current_path = if @options.has_key?(:current_path)
                        @options[:current_path].as(String?)
                      else
                        ENV[name]?
                      end
      @section = Helpers.create_section(name)
      @search_order = [] of Segment
    end

    # The plan:
    # 1. Determine initial search graph
    # 2. Find the files on each part of the graph
    # 3. Read the files
    # 4. Concatenate lines and remove duplicates
    # 5. Join into env var format
    def run : String
      determine_initial_search_graph
      find_files_in_graph
      read_files
      join_into_env_var_format
    end

    private def join_into_env_var_format : String
      current = @current_path
      if current && !current.empty?
        components = current.split(":")
        components.each do |line|
          next if @section.all_lines.has_key?(line)
          @section.all_lines[line] = nil
        end
        @section.found["current path"] = components
      end

      @section.all_lines.keys
        .join(":")
        .gsub("~", HOME)
    end

    private def read_files
      @section.found.each do |path, _|
        next unless File.file?(path)
        lines = File.read_lines(path).map(&.chomp)
        @section.found[path] = lines
        lines.each do |line|
          next if @section.all_lines.has_key?(line)
          @section.all_lines[line] = nil
        end
      end
    end

    private def find_files_in_graph
      @search_order.each do |segment|
        dirpath = @section.directories[segment]
        if Dir.exists?(dirpath)
          Dir.entries(dirpath).sort.each do |file|
            next if file.starts_with?(".")
            @section.found[File.join(dirpath, file)] = nil
          end
        end

        path = @section.files[segment]
        next unless File.exists?(path)
        @section.found[path] = nil
      end
    end

    private def determine_initial_search_graph
      @search_order = Helpers.determine_search_order(@options)

      # Filter directories and files to only include segments in search order
      @section.directories.reject! { |segment, _| !@search_order.includes?(segment) }
      @section.files.reject! { |segment, _| !@search_order.includes?(segment) }

      @section.search_order = @search_order
    end
  end
end
