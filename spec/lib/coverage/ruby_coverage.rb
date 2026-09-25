# Line coverage for the Ruby implementation, one process at a time.
#
# spec/lib/coverage/run.sh loads this into every Ruby process the suite starts
# by putting `-r<this file>` in RUBYOPT, and PATH_HELPER_COVERAGE_RAW names the
# directory the counts go to. No gem is involved, and nothing is added to the
# executable, which has to stay a self-contained script that runs on Ruby 2.6.
#
# Only a process whose program is the path_helper script is measured; any other
# -- the suite's timing helper runs `ruby -e` around each call -- is left alone.
# For that one, the stdlib Coverage module is started and the script is then run
# from here with `load`, rather than left for Ruby to run as the main program:
# before Ruby 3 (2.6 and 2.7 are both supported) Coverage does not count the
# lines of the main program at all. The script ends in `exit`, whose SystemExit
# carries the status out of this require just as it would out of the script;
# the `exit` below is only for a run that falls off the end. The script has no
# `__FILE__ == $0` guard, uses no DATA, and `__FILE__` names the same file, so
# it behaves exactly as it does when run directly.
#
# At exit the counts are written as JSON to a new file in the raw directory, and
# spec/lib/coverage/report.rb merges them. The suite compares the executable's
# stdout and stderr byte for byte and checks its exit status, so the recording
# must never print, raise or change the status: any failure is swallowed, and
# costs that run's counts and nothing else. at_exit handlers run LIFO and this
# one is registered before the script's, so it sees their lines too.

raw_dir = ENV["PATH_HELPER_COVERAGE_RAW"]
program = $0

if raw_dir && !raw_dir.empty? && File.basename(program) == "path_helper" && File.file?(program)
  script = File.expand_path(program)
  started = begin
    require "coverage"
    Coverage.start(lines: true)
    true
  rescue Exception # rubocop:disable Lint/RescueException
    false
  end

  if started
    at_exit do
      begin
        counts = Coverage.result[script]
        if counts
          require "json"
          lines = counts.is_a?(Hash) ? counts[:lines] : counts
          name = File.join(raw_dir, "ruby-#{Process.pid}-#{rand(1 << 32).to_s(16)}.json")
          File.open(name, File::WRONLY | File::CREAT | File::EXCL, 0o644) do |f|
            f.write(JSON.generate("file" => script, "lines" => lines))
          end
        end
      rescue Exception # rubocop:disable Lint/RescueException
        # Deliberately silent; see the top of the file.
        nil
      end
    end

    load script
    exit
  end
end
