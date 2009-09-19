require "rubygems"

begin
  require "jeweler"
rescue LoadError
  desc "Install gem using sudo"
  task(:install) do
    $stderr.puts "Jeweler not available. `gem install jeweler` to install this gem"
  end
else
  Jeweler::Tasks.new do |s|
    s.name      = "rack-test"
    s.author    = "Bryan Helmkamp"
    s.email     = "bryan" + "@" + "brynary.com"
    s.homepage  = "http://github.com/brynary/rack-test"
    s.summary   = "Simple testing API built on Rack"
    s.description  = <<-EOS.strip
Rack::Test is a small, simple testing API for Rack apps. It can be used on its
own or as a reusable starting point for Web frameworks and testing libraries
to build on. Most of its initial functionality is an extraction of Merb 1.0's
request helpers feature.
    EOS
    s.rubyforge_project = "rack-test"
    s.extra_rdoc_files = %w[README.rdoc MIT-LICENSE.txt]

    s.add_dependency "rack", ">= 1.0"
  end

  Jeweler::RubyforgeTasks.new

  task :spec => :check_dependencies

  namespace :version do
    task :verify do
      $LOAD_PATH.unshift "lib"
      require "rack/test"

      jeweler_version = Gem::Version.new(File.read("VERSION").strip)
      lib_version = Gem::Version.new(Rack::Test::VERSION)

      if jeweler_version != lib_version
        raise <<-EOS

  Error: Version number mismatch!

    VERSION: #{jeweler_version}
    Rack::Test::VERSION: #{lib_version}

        EOS
      end
    end
  end

  task :gemspec => "version:verify"
end

begin
  require "spec/rake/spectask"
rescue LoadError
  desc "Run specs"
  task(:spec) { $stderr.puts '`gem install rspec` to run specs' }
else
  Spec::Rake::SpecTask.new do |t|
    t.spec_opts = ['--options', "\"#{File.dirname(__FILE__)}/spec/spec.opts\""]
    t.libs << 'lib'
    t.libs << 'spec'
    t.warning = true
  end

  task :default => :spec

  desc "Run all specs in spec directory with RCov"
  Spec::Rake::SpecTask.new(:rcov) do |t|
    t.spec_opts = ['--options', "\"#{File.dirname(__FILE__)}/spec/spec.opts\""]
    t.libs << 'lib'
    t.libs << 'spec'
    t.warning = true
    t.rcov = true
    t.rcov_opts = ['-x spec']
  end
end

desc "Generate RDoc"
task :docs do
  FileUtils.rm_rf("doc")
  require "rack/test"
  system "hanna --title 'Rack::Test #{Rack::Test::VERSION} API Documentation'"
end

desc 'Removes trailing whitespace'
task :whitespace do
  sh %{find . -name '*.rb' -exec sed -i '' 's/ *$//g' {} \\;}
end

