require File.expand_path("../lib/#{File.basename(__FILE__, '.gemspec')}/version", __FILE__)

Gem::Specification.new do |s|
  s.name            = "path_helper"
  s.version         = PathHelper::VERSION
  s.date            = %q{2019-07-28}
  s.summary         = %q{A replacement for Apple's /usr/libexec/path_helper}
  s.authors         = ["Iain Barnett"]
  s.homepage        = "https://github.com/yb66/path_helper"
  s.email           = ["helpful-iain@theprintedbird.com"]
  s.files           = `git ls-files`.split($\)
  s.require_paths   = ["lib"]
  s.executables     = s.files.grep(%r{^exe/}).map{ |f| File.basename(f) }
end