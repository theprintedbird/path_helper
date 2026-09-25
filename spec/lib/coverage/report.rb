#!/usr/bin/env ruby
# Turns the raw coverage a suite run left behind into a report: a Markdown
# summary (per file line counts and percentage, and the uncovered line numbers
# as ranges) that is printed and also written to summary.md, plus whatever
# machine-readable form suits the language.
#
#   report.rb ruby  <title> <out dir> <raw dir> <source file> <display name>
#     Merges the per-process JSON written by spec/lib/coverage/ruby_coverage.rb
#     for <source file>, and writes a SimpleCov-compatible .resultset.json and
#     an annotated copy of the source (path_helper.txt, hit counts in the
#     margin) beside summary.md.
#
#   report.rb kcov  <title> <out dir> <kcov dir> <source root>
#     Reads the kcov-merged/codecov.json that `kcov --merge` wrote to
#     <kcov dir>; file names are shown relative to <source root>, the directory
#     holding src/. kcov's own HTML is in <kcov dir>.
#
# Called by spec/lib/coverage/run.sh. Plain stdlib, and Ruby 2.6 compatible
# like the rest of the project, since it runs on whatever Ruby the image has.

require "json"

# [[display name, [count or nil per line]]] -> Markdown
def summary title, files
  rows = []
  uncovered = []
  total_relevant = 0
  total_covered = 0
  files.each do |name, lines|
    relevant = lines.compact.size
    covered = lines.count { |c| c && c > 0 }
    total_relevant += relevant
    total_covered += covered
    rows << [name, relevant, covered, relevant - covered, percent(covered, relevant)]
    missed = []
    lines.each_with_index { |c, i| missed << i + 1 if c && c.zero? }
    uncovered << [name, ranges(missed)] unless missed.empty?
  end

  out = []
  out << "## Coverage: #{title}"
  out << ""
  out << "| File | Lines | Covered | Missed | Coverage |"
  out << "|------|------:|--------:|-------:|---------:|"
  rows.each { |r| out << "| `#{r[0]}` | #{r[1]} | #{r[2]} | #{r[3]} | #{r[4]} |" }
  if rows.size > 1
    out << "| **Total** | #{total_relevant} | #{total_covered} | " \
           "#{total_relevant - total_covered} | **#{percent(total_covered, total_relevant)}** |"
  end
  out << ""
  if uncovered.empty?
    out << "Every relevant line was run."
  else
    out << "Uncovered lines:"
    out << ""
    uncovered.each { |name, r| out << "- `#{name}`: #{r}" }
  end
  out.join("\n") + "\n"
end

def percent covered, relevant
  return "n/a" if relevant.zero?
  format("%.2f%%", 100.0 * covered / relevant)
end

# [3, 4, 5, 9] -> "3-5, 9"
def ranges numbers
  numbers.slice_when { |a, b| b != a + 1 }
         .map { |run| run.size == 1 ? run.first.to_s : "#{run.first}-#{run.last}" }
         .join(", ")
end

def ruby_report title, out_dir, raw_dir, source, display
  source_lines = File.readlines(source)
  merged = nil
  runs = 0
  Dir.glob(File.join(raw_dir, "ruby-*.json")).sort.each do |raw|
    data = JSON.parse(File.read(raw))
    lines = data["lines"]
    # A copy of a different script (or a stale file) would misalign the counts.
    if lines.size != source_lines.size
      warn "report.rb: skipping #{raw}: #{lines.size} lines, #{source} has #{source_lines.size}"
      next
    end
    runs += 1
    merged ||= Array.new(lines.size)
    lines.each_with_index do |c, i|
      merged[i] = (merged[i] || 0) + c unless c.nil?
    end
  end
  abort "report.rb: no coverage was recorded for #{source} in #{raw_dir}" unless merged

  resultset = {
    "path_helper shell suite" => {
      "coverage" => { File.expand_path(source) => { "lines" => merged } },
      "timestamp" => Time.now.to_i,
    },
  }
  File.write(File.join(out_dir, ".resultset.json"), JSON.pretty_generate(resultset) + "\n")

  width = merged.compact.max.to_s.size
  annotated = source_lines.each_with_index.map do |text, i|
    c = merged[i]
    margin = c.nil? ? "" : (c.zero? ? "#####" : c.to_s)
    format("%#{[width, 5].max}s %4d: %s", margin, i + 1, text.chomp)
  end
  File.write(File.join(out_dir, "path_helper.txt"), annotated.join("\n") + "\n")

  summary("#{title} (#{runs} runs)", [[display, merged]])
end

def kcov_report title, out_dir, kcov_dir, source_root
  codecov = File.join(kcov_dir, "kcov-merged", "codecov.json")
  abort "report.rb: #{codecov} not found; did kcov record anything?" unless File.file?(codecov)
  root = File.expand_path(source_root) + "/"
  files = JSON.parse(File.read(codecov)).fetch("coverage").map do |file, per_line|
    # One entry per line in kcov's line table: a hit count, or "hits/possible"
    # in some kcov versions. Lines with no entry are, like Ruby's nils, not
    # relevant.
    last = per_line.keys.map(&:to_i).max || 0
    lines = Array.new(last)
    per_line.each do |number, value|
      lines[number.to_i - 1] = value.to_s.split("/").first.to_i
    end
    [display_name(file, root), lines]
  end
  summary(title, files.sort_by(&:first))
end

# kcov names a file relative to the directory all the measured files share
# (path_helper.cr, path_helper/cli.cr), or absolutely; either way it is shown
# relative to the project root, as src/path_helper.cr.
def display_name file, root
  return file[root.size..-1] if file.start_with?(root)
  found = Dir.glob(File.join(root, "**", file)).first
  found ? found[root.size..-1] : file
end

mode, title, out_dir, *rest = ARGV
text =
  case mode
  when "ruby" then ruby_report(title, out_dir, *rest)
  when "kcov" then kcov_report(title, out_dir, *rest)
  else abort "usage: report.rb ruby|kcov <title> <out dir> ..."
  end
File.write(File.join(out_dir, "summary.md"), text)
print text
