require File.dirname(__FILE__) + "/spec_helper"

describe Rack::Test do
  before do
    @session = Rack::Test::Session.new(App)
  end

  def request
    @session.last_request
  end

  def response
    @session.last_response
  end

  describe "#get" do
    it "requests URL" do
      @session.get "/"
      response.should be_ok
    end

    it "allows to specify the query string" do
      @session.get "/", :foo => "bar"

      request.GET.should == { "foo" => "bar" }
    end

    it "allows to modify the rack env" do
      @session.get "/", :headers => { "User-Agent" => "Rack::Test" }
      request.env["User-Agent"].should == "Rack::Test"

      @session.get "/", :env => { "X-Foo" => "bar" }
      request.env["X-Foo"].should == "bar"
    end
  end
end
