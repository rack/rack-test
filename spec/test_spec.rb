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
    end
  end

  describe "#post" do
    it "requests URL" do
      @session.post "/"
      response.should be_ok
    end

    it "allows to post a body" do
      @session.post "/", "Lobsterlicious!"
      request.body.read.should == "Lobsterlicious!"
    end

    it "allows to specify params" do
      @session.post "/", :foo => "bar"
      request.POST.should == { "foo" => "bar" }
    end

    it "allows to specify headers" do
      @session.post "/", :headers => { "X-Foo" => "bar" }
      request.env["X-Foo"].should == "bar"
    end

    it "allows to specify both a body and headers" do
      @session.post "/", "foobar", :headers => { "X-Answer", "42" }
      request.body.read.should == "foobar"
      request.env["X-Answer"].should == "42"
    end
  end
end
