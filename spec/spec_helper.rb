require 'rspec'
require 'rspec/given'
Spec_dir = File.expand_path( File.dirname __FILE__ )

if ENV["DEBUG"]
  warn "DEBUG MODE ON"
  require 'pry-byebug'
  binding.pry
end

# code coverage
require 'simplecov'
SimpleCov.start do
  add_filter "/vendor/"
  add_filter "/vendor.noindex/"
  add_filter "/bin/"
  add_filter "/spec/"
  add_filter "/coverage/" # It used to do this for some reason, defensive of me.
end


Dir[ File.join( Spec_dir, "/support/**/*.rb")].each do |f|
  require f
end