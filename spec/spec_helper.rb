require "rubygems"
require "bundler/setup"

require "codeclimate-test-reporter"
CodeClimate::TestReporter.start

require "rack"
require "rspec"

Dir[File.dirname(__FILE__) + "/support/**/*.rb"].each {|f| require f}

require "rack/test"
require File.dirname(__FILE__) + "/fixtures/fake_app"

RSpec.configure do |config|
  config.mock_with :rspec
  config.include Rack::Test::Methods

  def app
    Rack::Lint.new(Rack::Test::FakeApp.new)
  end

  def check(*args)
  end
end
