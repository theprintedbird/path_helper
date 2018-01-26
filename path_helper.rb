#!/usr/bin/ruby

## A better path helper - don't put the standard bins first.

require 'optparse'
require 'pathname'

VERSION = "2.2.0"

OPTIONS = {}
OptionParser.new do |opts|
	opts.banner = "Usage: path_helper.rb [options]"
	opts.on("-p", "--path [PATH]", "Current path") do |cp|
		OPTIONS[:path] = cp || false
	end
	opts.on("-m", "--man", 'Run for man pages but perhaps read `man manpages` first') do
		OPTIONS[:man] = true
	end
	opts.on("--dyld [DYLD]", 'DYLD_FALLBACK_FRAMEWORK_PATH env var') do |dyld|
		OPTIONS[:dyld] = dyld || true
	end
	opts.on("-c", "--c-include [C_INCLUDE]", 'C_INCLUDE_PATH env var') do |ci|
		OPTIONS[:ci] = ci || true
	end
	opts.on("-v", "--[no-]verbose", "Run verbosely") do |v|
		OPTIONS[:verbose] = v
	end
	opts.on("-d", "--[no-]debug", "Debug mode, even more output") do
		OPTIONS[:debug] = true
	end
	opts.on( '--version', 'Print version') do
    warn VERSION
    exit 0
  end
	opts.on( '-h', '--help', 'Display this screen') do
    warn opts
    exit 1
  end
end.parse!

warn "OPTIONS = #{OPTIONS.inspect}" if OPTIONS[:debug]

if ENV["DEBUG"]
	OPTIONS[:debug] = true
end
if OPTIONS[:debug]
	OPTIONS[:verbose] = true
end

BASE_PATHS = [
	Pathname(ENV["HOME"]).join(".config/paths"),
	Pathname(ENV["HOME"]).join("Library/Paths"),
	Pathname("/etc"),
]
warn "BASE_PATHS = #{BASE_PATHS.inspect}" if OPTIONS[:debug]

DEFAULT_PATHS = ["paths", "paths.d"]
if OPTIONS[:man]
	DEFAULT_PATHS.map!{|x| "man#{x}" }
elsif OPTIONS[:dyld]
	DEFAULT_PATHS.map!{|x| "dyld_#{x}" }
elsif OPTIONS[:ci]
	DEFAULT_PATHS.map!{|x| "include_#{x}" }
end
warn "DEFAULT_PATHS = #{DEFAULT_PATHS.inspect}" if OPTIONS[:debug]

PATHS= Hash[ BASE_PATHS.map{|base| DEFAULT_PATHS.map{|x| base.join x } }]

warn "PATHS = #{PATHS.inspect}" if OPTIONS[:debug]

if OPTIONS[:man]
	CURRENT_PATH = ENV["MANPATH"] || `man -w`
elsif OPTIONS[:dyld]
	if OPTIONS[:dyld].respond_to? :split
		CURRENT_PATH = OPTIONS[:dyld]
	else
		CURRENT_PATH = ENV["DYLD_FALLBACK_FRAMEWORK_PATH"]
	end
elsif OPTIONS[:ci]
	if OPTIONS[:ci].respond_to? :split
		CURRENT_PATH = OPTIONS[:ci]
	else
		CURRENT_PATH = ENV["C_INCLUDE_PATH"]
	end
else
	if OPTIONS[:path].respond_to? :split
		CURRENT_PATH = OPTIONS[:path]
	else
		CURRENT_PATH = ENV["PATH"]
	end
end
warn "CURRENT_PATH = #{CURRENT_PATH.inspect}" if OPTIONS[:debug]

def output_debug_lines lines
	warn lines.map{|x| "\t#{x}\n" }.join if OPTIONS[:debug]
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
		_pathsd = pathsd.children.select{|file| file.file? and not file.basename.to_s =~ /^\./ }
		if not _pathsd.empty?
			warn "Getting paths from #{pathsd}" if OPTIONS[:verbose]
			_pathsd.each do |file|
				@entries += read_file file
			end
		end
	end

	paths = Pathname(paths_file)
	if paths.exist?
		warn "Getting paths from #{paths}" if OPTIONS[:verbose]
		@entries += read_file paths
	end
  @entries
end

def join_up entries
	entries.reject(&:empty?)
				.uniq
				.map{|x| x.sub /\~/, ENV["HOME"]}
				.join(":")
end

warn "DEBUG MODE" if OPTIONS[:debug]

entries = []
PATHS.each do |(paths_file, paths_dir)|
	entries += path_helper( paths_file, paths_dir )
end

unless CURRENT_PATH.nil? or CURRENT_PATH.empty?
	warn "Current path:" if OPTIONS[:debug]
	lines = CURRENT_PATH.split(/\:+/)
  output_debug_lines lines
	entries += lines
end

final = join_up entries

if OPTIONS[:verbose]
  warn "PATH:\n#{final}"
  warn "\nIf you expected items you'd inserted in the path manually to show up earlier then either clear the path before running this and reinsert or add paths via (~/Library/Paths|~/config)/#{DEFAULT_PATHS.first} and (~/Library/Paths|~/config)/#{DEFAULT_PATHS.last}/*)\n\n"
end

print final

exit 0
