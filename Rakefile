require 'rspec/core'
require 'rspec/core/rake_task'

task default: :spec

RSpec::Core::RakeTask.new do |t|
  t.pattern = 'spec/**/*_spec.rb'
  t.ruby_opts = '-w'
end

RSpec::Core::RakeTask.new(:spec_cov) do |t|
  ENV['COVERAGE'] = '1'
  t.pattern = 'spec/**/*_spec.rb'
  t.ruby_opts = '-w'
end

begin
  require 'rubocop/rake_task'
  RuboCop::RakeTask.new
rescue LoadError
  task :rubocop do
    warn 'Rubocop not supported on this configuration.'
  end
end

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
