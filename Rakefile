require 'rubygems'

require 'rspec/core'
require 'rspec/core/rake_task'

task default: %i[rubocop spec]

RSpec::Core::RakeTask.new do |t|
  t.pattern = 'spec/**/*_spec.rb'
  t.ruby_opts = '-w'
end

require 'rubocop/rake_task'
RuboCop::RakeTask.new

desc 'Generate RDoc'
task :docs do
  FileUtils.rm_rf('doc')
  require 'rack/test/version'
  sh "rdoc --title 'Rack::Test #{Rack::Test::VERSION} API Documentation'"
end

desc 'Removes trailing whitespace'
task :whitespace do
  sh %(find . -name '*.rb' -exec sed -i 's/ *$//g' {} \\;)
end
