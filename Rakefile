require "rake/testtask"

task default: :spec

desc "Run specs"
task "spec" do
  sh "#{FileUtils::RUBY} -w spec/all.rb"
end

desc "Run specs with coverage"
task "spec_cov" do
  ENV['COVERAGE'] = '1'
  sh "#{FileUtils::RUBY} -w spec/all.rb"
  ENV.delete('COVERAGE')
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
