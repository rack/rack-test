require "rubygems"
require "rake/gempackagetask"
require "rake/clean"
require "spec/rake/spectask"
require "./lib/rack/test"

Spec::Rake::SpecTask.new do |t|
  t.spec_opts == ["--color"]
end

desc "Run the specs"
task :default => :spec

spec = Gem::Specification.new do |s|
  s.name         = "rack-test"
  s.version      = Rack::Test::VERSION
  s.author       = "Bryan Helmkamp"
  s.email        = "bryan" + "@" + "brynary.com"
  s.homepage     = "http://github.com/brynary/rack-test"
  s.summary      = "Simple testing API built on Rack"
  s.description  = s.summary
  s.files        = %w[Rakefile] + Dir["lib/**/*"]
end

Rake::GemPackageTask.new(spec) do |package|
  package.gem_spec = spec
end

desc 'Install the package as a gem.'
task :install => [:clean, :package] do
  gem = Dir['pkg/*.gem'].first
  sh "sudo gem install --local #{gem}"
end
