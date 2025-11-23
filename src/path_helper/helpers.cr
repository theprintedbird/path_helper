module PathHelper
  HOME = Path.home.to_s

  enum Segment
    Lib
    Config
    Etc
  end

  SEGMENTS = [Segment::Lib, Segment::Config, Segment::Etc]

  # Section holds all the data for building a path
  class Section
    property name : String
    property directories : Hash(Segment, String)
    property files : Hash(Segment, String)
    property found : Hash(String, Array(String)?)
    property all_lines : Hash(String, Nil)
    property search_order : Array(Segment)

    def initialize(@name, @directories, @files)
      @found = Hash(String, Array(String)?).new
      @all_lines = Hash(String, Nil).new
      @search_order = [] of Segment
    end
  end

  class Error < Exception
  end

  module Helpers
    def self.default_order : Array(Segment)
      {% if flag?(:darwin) %}
        [Segment::Lib, Segment::Config, Segment::Etc]
      {% else %}
        [Segment::Config, Segment::Lib, Segment::Etc]
      {% end %}
    end

    def self.determine_search_order(options : Hash(Symbol, String | Bool | Nil)) : Array(Segment)
      order = default_order

      order.reject do |k|
        # Get the option key for this segment
        opt_key = case k
                  when Segment::Lib    then :lib
                  when Segment::Config then :config
                  when Segment::Etc    then :etc
                  else                      :etc
                  end

        # Reject if explicitly false, or if it's the secondary default and not explicitly true
        (options[opt_key]? == false) ||
          (k == order[1] && options[opt_key]? != true)
      end
    end

    def self.create_section(name : String) : Section
      downcased = "#{name.downcase}s"

      directories = {
        Segment::Lib    => "#{HOME}/Library/Paths/#{downcased}.d",
        Segment::Config => "#{HOME}/.config/paths/#{downcased}.d",
        Segment::Etc    => "/etc/#{downcased}.d",
      }

      files = {
        Segment::Lib    => "#{HOME}/Library/Paths/#{downcased}",
        Segment::Config => "#{HOME}/.config/paths/#{downcased}",
        Segment::Etc    => "/etc/#{downcased}",
      }

      Section.new(name, directories, files)
    end
  end
end
