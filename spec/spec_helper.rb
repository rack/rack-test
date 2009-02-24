$: << File.dirname(__FILE__) + "/../lib"

require "spec"
require "rack/test"
require "rack/lobster"

App = Rack::Lobster.new

