require "rake/testtask"

task default: :spec

Rake::TestTask.new("spec") do |t|
  t.libs << "test"
  t.test_files = FileList["spec/**/*_spec.rb"]
  t.warning = true
  t.verbose = true
end

desc "Run specs with coverage"
task "spec_cov" do
  ENV['COVERAGE'] = '1'
  Rake::Task['spec'].invoke
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
