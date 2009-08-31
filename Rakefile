require "rubygems"
require "rake/rdoctask"
require "spec/rake/spectask"

begin
  require "jeweler"

  Jeweler::Tasks.new do |s|
    s.name      = "rack-test"
    s.author    = "Bryan Helmkamp"
    s.email     = "bryan" + "@" + "brynary.com"
    s.homepage  = "http://github.com/brynary/rack-test"
    s.summary   = "Simple testing API built on Rack"
    # s.description = "TODO"
    s.rubyforge_project = "rack-test"
    s.extra_rdoc_files = %w[README.rdoc MIT-LICENSE.txt]
  end

  Jeweler::RubyforgeTasks.new
rescue LoadError
  puts "Jeweler not available. Install it with: gem install jeweler"
end

Spec::Rake::SpecTask.new do |t|
  t.spec_opts = ['--options', "\"#{File.dirname(__FILE__)}/spec/spec.opts\""]
  t.libs << 'lib'
  t.libs << 'spec'
end

desc "Run all specs in spec directory with RCov"
Spec::Rake::SpecTask.new(:rcov) do |t|
  t.spec_opts = ['--options', "\"#{File.dirname(__FILE__)}/spec/spec.opts\""]
  t.rcov = true
  t.rcov_opts = lambda do
    IO.readlines(File.dirname(__FILE__) + "/spec/rcov.opts").map {|l| l.chomp.split " "}.flatten
  end
end

desc "Generate RDoc"
task :docs do
  FileUtils.rm_rf("doc")
  system "hanna --title 'Rack::Test #{Rack::Test::VERSION} API Documentation'"
end

desc 'Removes trailing whitespace'
task :whitespace do
  sh %{find . -name '*.rb' -exec sed -i '' 's/ *$//g' {} \\;}
end

task :spec => :check_dependencies

desc "Run the specs"
task :default => :spec