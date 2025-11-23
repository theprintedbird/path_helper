module PathHelper
  class Debug
    # Symbol to use when there are more children to come.
    T = " \u251C\u2500\u2500"

    # Symbol to use for last child.
    L = " \u2514\u2500\u2500"

    # Symbol to use for a child while another branch is being displayed.
    I = " \u2502  "

    # Space.
    N = "    "

    def initialize(@helper : CLI)
      @section = @helper.section
    end

    # Format options hash to match Ruby output format
    private def format_options : String
      pairs = @helper.options.map do |k, v|
        value = case v
                when String
                  v.empty? ? "\"\"" : "\"#{v}\""
                when Bool
                  v.to_s
                when Nil
                  "nil"
                else
                  v.to_s
                end
        ":#{k}=>#{value}"
      end
      "{#{pairs.join(", ")}}"
    end

    # Format search order to match Ruby symbol array format
    private def format_search_order : String
      symbols = @section.search_order.map do |segment|
        case segment
        when Segment::Lib    then ":lib"
        when Segment::Config then ":config"
        when Segment::Etc    then ":etc"
        end
      end
      "[#{symbols.join(", ")}]"
    end

    # tree style render
    def render : String
      output = [] of String
      findings = Hash(String, Int32).new(0)
      dup_text = " #{Colors::RED}\u2717#{Colors::NORMAL}"

      output << "Name: #{Colors::GREEN}#{@section.name}#{Colors::NORMAL}"
      output << "Options: #{format_options}"
      output << "Search order: #{format_search_order}"

      @section.search_order.each do |segment|
        if dir = @section.directories[segment]?
          output << "\t#{Colors::YELLOW}#{dir}#{Colors::NORMAL}"
        end
        if file = @section.files[segment]?
          output << "\t#{Colors::CYAN}#{file}#{Colors::NORMAL}"
        end
      end

      output << "\nResults: (duplicates marked by#{dup_text})\n"

      @section.found.each do |file, lines|
        if File.file?(file)
          output << "#{Colors::CYAN}#{file}#{Colors::NORMAL}"
        else
          output << "#{Colors::RED}#{file} - does not exist!#{Colors::NORMAL}"
          next
        end

        next if lines.nil?

        non_empty_lines = lines.compact.reject(&.empty?)
        non_empty_lines.each_with_index do |line, i|
          findings[line] = findings[line] + 1
          is_last = i == non_empty_lines.size - 1
          is_dup = findings[line] >= 2
          color = is_dup ? Colors::RED : Colors::GREEN
          dup_marker = is_dup ? dup_text : ""
          output << "#{is_last ? L : T} #{color}#{line}#{Colors::NORMAL}#{dup_marker}"
        end
      end

      output.join("\n")
    end
  end
end
