$:.unshift(File.expand_path("../lib", File.dirname(__FILE__)))

if ENV.delete('COVERAGE')
  require 'simplecov'
  SimpleCov.start do
    enable_coverage :branch
    add_filter "/spec/"
    add_group('Missing'){|src| src.covered_percent < 100}
    add_group('Covered'){|src| src.covered_percent == 100}
  end
end

ENV['MT_NO_PLUGINS'] = '1' # Work around stupid autoloading of plugins
gem 'minitest'
require 'minitest/global_expectations/autorun'

require 'rack/test'
require_relative 'fixtures/fake_app'

class Minitest::Spec
  include Rack::Test::Methods

  def app
    Rack::Test::FAKE_APP
  end

  def self.deprecated(*args, &block)
    it(*args) do
      begin
        verbose, $VERBOSE = $VERBOSE, nil
        instance_exec(&block)
      ensure
        $VERBOSE = verbose
      end
    end
  end
end
