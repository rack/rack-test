require "rubygems"
require "spec"
require File.expand_path(File.dirname(__FILE__) + "/../lib/rack/test")
require File.dirname(__FILE__) + "/fixtures/fake_app"

describe "any #verb methods", :shared => true do
  it "requests the URL using VERB" do
    send(verb, "/")
    
    last_request.env["REQUEST_METHOD"].should == verb.upcase
    last_response.should be_ok
  end

  it "uses the provided params hash" do
    unless %(head put delete).include?(verb)
      send(verb, "/", :foo => "bar")
      last_request.send(verb.upcase).should == { "foo" => "bar" }
    end
  end

  it "uses the provided env" do
    send(verb, "/", {}, { "User-Agent" => "Rack::Test" })
    last_request.env["User-Agent"].should == "Rack::Test"
  end
  
  it "yields the response to a given block" do
    yielded = false
    
    send(verb, "/") do |response|
      response.should be_ok
      yielded = true
    end
    
    yielded.should be_true
  end
end
