require "rubygems"


require 'rspec/core'
require "rspec/core/rake_task"

task default: :spec

RSpec::Core::RakeTask.new do |t|
  t.pattern = "spec/**/*_spec.rb"
  t.ruby_opts = "-w"
end

require 'rubocop/rake_task'
RuboCop::RakeTask.new

# desc "Run all specs in spec directory with RCov"
# RSpec::Core::RakeTask.new(:rcov) do |t|
#   t.libs << 'lib'
#   t.libs << 'spec'
#   t.warning = true
#   t.rcov = true
#   t.rcov_opts = ['-x spec']
# end

desc "Generate RDoc"
task :docs do
  FileUtils.rm_rf("doc")
  require "rack/test/version"
  sh "rdoc --title 'Rack::Test #{Rack::Test::VERSION} API Documentation'"
end

desc 'Removes trailing whitespace'
task :whitespace do
  sh %{find . -name '*.rb' -exec sed -i 's/ *$//g' {} \\;}
end
