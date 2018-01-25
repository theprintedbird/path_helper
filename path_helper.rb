#!/usr/bin/ruby

## A better path helper - don't put the standard bins first.

require 'pathname'

ETC_PATHS         = Pathname("/etc/paths")    # a file
ETC_PATHS_D       = Pathname("/etc/paths.d")  # a directory

CURRENT_PATH = ARGV.shift || ENV["PATH"]

def output_debug_lines lines
	warn lines.map{|x| "\t#{x}\n" }.join if ENV["DEBUG"]
end

def read_file file
  lines = File.readlines( file ).map(&:chomp)
  output_debug_lines lines
  lines
end


# Expects a layout of:
# 	DIR/paths
# 	DIR/paths.d/*
def path_helper paths_file, paths_dir
  # Simplest way, slurp the file contents into an array
  @entries = []

	pathsd = Pathname(paths_dir)
	if pathsd.exist?
		warn "Getting paths from #{pathsd}" if ENV["DEBUG"]
		pathsd.each_child do |file|
			next unless file.file?
			next if file.basename.to_s =~ /^\./
			@entries += read_file file
		end
	end

	paths = Pathname(paths_file)
	if paths.exist?
		warn "Getting paths from #{paths}"
		@entries += read_file paths
	end
  @entries
end

def join_up entries
	entries.reject(&:empty?).uniq.join(":")
end

warn "DEBUG MODE" if ENV["DEBUG"]

entries = []
[
	[ETC_PATHS, ETC_PATHS_D],
].each do |(paths_file, paths_dir)|
	entries += path_helper( paths_file, paths_dir )
end

unless CURRENT_PATH.nil? or CURRENT_PATH.empty?
	warn "Current path:"
	lines = CURRENT_PATH.split(/\:+/)
  output_debug_lines lines
	entries += lines
end

final = join_up entries

if ENV["DEBUG"]
  warn "PATH:\n#{final}"
else
 print final
end

exit 0
