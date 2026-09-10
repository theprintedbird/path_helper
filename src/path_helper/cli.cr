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

			# A tilde is only a home directory when preceding a component, and only
      # when it is the whole component or followed by a slash. Anywhere else
      # it is part of a name.
			# The block form prevents a backslash in HOME being read as a back-reference.
      @section.all_lines.keys
        .map { |line| line.sub(/\A~(?=\/|\z)/) { HOME } }
        .join(":")
    end

    private def read_files
      @section.found.each do |path, _|
        next unless File.file?(path)
        # Blank lines are dropped here rather than at the join, so that
        # everything downstream gets real components. Empty lines would
        # join as `::`, which is the current working directory
        # and thus a security problem to be avoided. A line of nothing but
        # whitespace is blank too -- it is not `empty?` once chomped, so it
        # has to be tested stripped. Only the test is stripped: a line with
        # a path in it keeps the whitespace around that path, since a path
        # may legitimately contain spaces.
        lines = File.read_lines(path).map(&.chomp).reject { |line| line.strip.empty? }
        # When a colon is present, it would reach PATH as two components,
        # so those items are dropped and reported to STDERR or in the debug report.
        dropped, kept = lines.partition { |line| line.includes?(":") }
        dropped.each do |line|
          unless @options[:quiet]? == true
            STDERR.puts "#{Colors::YELLOW}#{path}: ignoring '#{line}', a path cannot contain a colon#{Colors::NORMAL}"
          end
          @section.dropped[line] = nil
        end
        # The dropped lines stay in :found so the debug report can use them.
        @section.found[path] = lines
        kept.each do |line|
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
