module PathHelper
  module Colors
    # Check if we can use colors
    private def self.tput_available? : Bool
      return false unless STDOUT.tty?
      result = Process.run("which", ["tput"])
      result.success?
    end

    # Get color code from tput
    private def self.tput(args : Array(String)) : String
      output = IO::Memory.new
      Process.run("tput", args, output: output)
      output.to_s
    rescue
      ""
    end

    {% if flag?(:fake_colors) %}
      NORMAL = ""
      RED    = ""
      GREEN  = ""
      YELLOW = ""
      CYAN   = ""
    {% else %}
      NORMAL = tput_available? ? tput(["sgr0"]) : ""
      RED    = tput_available? ? tput(["setaf", "1"]) : ""
      GREEN  = tput_available? ? tput(["setaf", "2"]) : ""
      YELLOW = tput_available? ? tput(["setaf", "3"]) : ""
      CYAN   = tput_available? ? tput(["setaf", "6"]) : ""
    {% end %}
  end
end
