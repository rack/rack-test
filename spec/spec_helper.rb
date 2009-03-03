require "rubygems"
require "spec"
require File.expand_path(File.dirname(__FILE__) + "/../lib/rack/test")
require File.dirname(__FILE__) + "/fixtures/fake_app"

describe "any #verb methods", :shared => true do
  it "requests the URL using VERB" do
    @session.send(verb, "/")
    request.env["REQUEST_METHOD"].should == verb.upcase
    response.should be_ok
  end

  it "uses the provided params hash" do
    unless %(head put delete).include?(verb)
      @session.send(verb, "/", :foo => "bar")
      request.send(verb.upcase).should == { "foo" => "bar" }
    end
  end

  it "uses the provided env" do
    @session.send(verb, "/", {}, { "User-Agent" => "Rack::Test" })
    request.env["User-Agent"].should == "Rack::Test"
  end
end
