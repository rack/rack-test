require File.dirname(__FILE__) + "/spec_helper"

describe Rack::Test::Session do
  before do
    @session = Rack::Test::Session.new(App)
  end

  def request
    @session.last_request
  end

  def response
    @session.last_response
  end

  describe "#request" do
    it "requests the URI" do
      @session.request "/"
      response.should be_ok
    end
    
    it "uses the provided env" do
      @session.request "/", "X-Foo" => "bar"
      request.env["X-Foo"].should == "bar"
    end
    
    it "defaults to GET" do
      pending do
        @session.request "/"
        request.env["REQUEST_METHOD"].should == "GET"
      end
    end
    
    it "defaults to HTTP" do
      pending do
        @session.request "/"
        request.env["SERVER_PORT"].should == "80"
        request.env["HTTPS"].should == "off"
      end
    end
    
    it "defaults to example.org" do
      pending do
        @session.request "/"
        puts request.env.inspect
        request.env["HTTP_HOST"].should == "example.org"
      end
    end
    
    it "keeps a cookie jar"
    it "sends multipart requests"
    
    it "yields the response to a given block" do
      @session.request "/" do |response|
        response.should be_ok
      end
    end
    
    it "calls callbacks before each request"
    it "calls callbacks after each request"
        
    context "when the URL is https://" do
      it "sets SERVER_PORT to 443"
      it "sets HTTPS to on"
    end
  end
  
  describe "#last_request" do
    it "returns the most recent request"
    it "raises an error if no requests have been issued"
  end
  
  describe "#last_response" do
    it "returns the most recent response"
    it "raises an error if no requests have been issued"
  end
  
  describe "#get" do
    it "requests the URL using GET" do
      @session.get "/"
      request.env["REQUEST_METHOD"].should == "GET"
      response.should be_ok
    end
    
    it "accepts a params hash" do
      @session.get "/", :foo => "bar"
      request.GET.should == { "foo" => "bar" }
    end
    
    it "uses the provided env" do
      @session.get "/", {}, { "User-Agent" => "Rack::Test" }
      request.env["User-Agent"].should == "Rack::Test"
    end
  end
  
  describe "#post" do
    it "requests the URL using POST" do
      @session.post "/"
      request.env["REQUEST_METHOD"].should == "POST"
      response.should be_ok
    end
    
    it "accepts a params hash" do
      @session.post "/", "Lobsterlicious!"
      request.body.read.should == "Lobsterlicious!"
    end
    
    it "uses the provided env" do
      @session.post "/", {}, { "X-Foo" => "bar" }
      request.env["X-Foo"].should == "bar"
    end
  end
  
  describe "#put" do
    it "requests the URL using PUT"
    it "accepts a params hash"
    it "uses the provided env"
  end
  
  describe "#delete" do
    it "requests the URL using DELETE"
    it "accepts a params hash"
    it "uses the provided env"
  end
end
