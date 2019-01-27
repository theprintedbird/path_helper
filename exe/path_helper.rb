#!/usr/bin/ruby

## A better path helper - don't put the standard bins first.

require 'optparse'
require 'pathname'

require_relative "../lib/path_helper/version.rb"

options = {}
OptionParser.new do |opts|
	opts.banner = "Usage: path_helper.rb [options]"
	opts.on("-p", "--path [PATH]", "Either pass the current path, a path you wish appended, or an empty string / nothing at all to start with a clean slate") do |cp|
		options[:path] = cp || false
	end
	opts.on("-m", "--man", 'Run for man pages but perhaps read `man manpages` first') do
		options[:man] = true
	end
	opts.on("--dyld [DYLD]", 'DYLD_FALLBACK_FRAMEWORK_PATH env var') do |dyld|
		options[:dyld] = dyld || true
	end
	opts.on("-c", "--c-include [C_INCLUDE]", 'C_INCLUDE_PATH env var') do |ci|
		options[:ci] = ci || true
	end
	opts.on("-v", "--[no-]verbose", "Run verbosely") do |v|
		options[:verbose] = v
	end
	opts.on("-d", "--[no-]debug", "Debug mode, even more output") do
		options[:debug] = true
	end
	opts.on( '--version', 'Print version') do
    warn VERSION
    exit 0
  end
	opts.on_tail("-h", "--help", "Show this message") do
		warn opts
		exit
	end
	
	if ARGV.empty?
		warn opts
		exit
	end
end.parse!

if ENV["DEBUG"]
	options[:debug] = true
end
if options[:debug]
	options[:verbose] = true
end

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
			:ci		=>	"C_INCLUDE_PATH",
			:dyld	=>	"DYLD_FALLBACK_FRAMEWORK_PATH",
			:man	=>	"MANPATH",
			:path	=>	"PATH"
		}


		def initialize options
			@options = options
			@base_paths = BASE_PATHS.dup
			@context_paths = DEFAULT_PATHS.dup
			@tree = {}
			@current_path = options[:path] || ""

			@key = [:man, :dyld, :ci, :path].find{|x| @options.has_key? x } || :path
			send "init_#{@key}"
			@entries = Entries.new @additional_path
		end


		def base_init item
			@tree = @base_paths.each_with_object({}) {|base,tree|
				@context_paths.each{|x|
					tree[ base.join item.(x) ] = []
				}
				tree # redundant but I like it
			}
		end


		def options_or_try_env name
			if @options[name].respond_to? :split
				@additional_path = @options[name]
			end
			@current_path = ENV[ ENV_NAMES[name] ]
		end


		def init_ci
			base_init ->(x){ "include_#{x}" }
			options_or_try_env :ci
		end


		def init_dyld
			base_init ->(x){ "dyld_#{x}" }
			options_or_try_env :dyld
		end


		def init_path
			base_init ->(x){ x }
			options_or_try_env :path
		end


		def init_man
			base_init ->(x){ "man#{x}" }
			@current_path = ENV["MANPATH"] || `man -w`
		end


		def output_debug_lines lines
			warn lines.map{|x| "\t#{x}\n" }.join if @options[:debug]
		end


		def read_file file
			lines = File
			#output_debug_lines lines
			lines
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
									pn.readlines(chomp: true )
										.each do |line|
											@entries.add line, pn
										end
								end
					else
						@tree[leaf] << leaf
						leaf.readlines(chomp: true )
								.each do |line|
									@entries.add line, leaf
								end
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


	class Entries
		def initialize additional=nil
			@entries = {} 
			@additional = if additional
				additional.respond_to?(:compact) ? additional : [additional]
			else
				nil
			end
		end


		def add( entry, origin )
			if @entries.has_key? entry
				@entries[entry] << origin
			else
				@entries[entry] = [origin]
			end
		end


		def ready
			interim = @entries.map{|entry,_| entry }
			if @additional
				interim += @additional
			end
			path_format interim
		end


		def path_format xs
			xs.compact
				.uniq
				.map{|x| x.sub /\~/, ENV["HOME"]}.join(":")
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

helper = PathHelper::CLI.new options
print helper.paths


exit 0
