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

desc 'Generate RDoc'
task :docs do
  FileUtils.rm_rf('doc')
  require_relative 'lib/rack/test/version'
  sh "rdoc --title 'Rack::Test #{Rack::Test::VERSION} API Documentation'"
end
