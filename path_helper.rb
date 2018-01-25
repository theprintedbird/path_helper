#!/usr/bin/ruby

## A better path helper - don't put the standard bins first.

require 'pathname'

ETC_PATHS         = Pathname("/etc/paths")    # a file
ETC_PATHS_D       = Pathname("/etc/paths.d")  # a directory

CURRENT_PATH = ARGV.shift || ENV["PATH"]

def read_file file
  File.readlines( file ).map(&:chomp)
end

def path_helper
  # Simplest way, slurp the file contents into an array
  @entries = []

  Pathname(ETC_PATHS_D).each_child do |file|
    next unless file.file?
    next if file.basename.to_s =~ /^\./
    @entries += read_file file
  end

  @entries += read_file Pathname(ETC_PATHS)

	unless CURRENT_PATH.nil? or CURRENT_PATH.empty?
		@entries += CURRENT_PATH.split(/\:+/)
	end
  @entries.uniq.join(":")
end

if ENV["DEBUG"]
  warn "DEBUG MODE"
  warn path_helper
else
 path = path_helper
 print path
end

exit 0