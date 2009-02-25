require File.dirname(__FILE__) + "/spec_helper"

describe Rack::Test::Session do
  before do
    app = Rack::Test::FakeApp.new
    @session = Rack::Test::Session.new(app)
  end

  def request
    @session.last_request
  end

  def response
    @session.last_response
  end

  describe "#request" do
    it "requests the URI using GET by default" do
      @session.request "/"
      request.should be_get
      response.should be_ok
    end
    
    it "returns a response" do
      @session.request("/").should be_ok
    end
    
    it "uses the provided env" do
      @session.request "/", "X-Foo" => "bar"
      request.env["X-Foo"].should == "bar"
    end
    
    it "defaults to GET" do
      @session.request "/"
      request.env["REQUEST_METHOD"].should == "GET"
    end
    
    it "defaults the REMOTE_ADDR to 127.0.0.1" do
      @session.request "/"
      request.env["REMOTE_ADDR"].should == "127.0.0.1"
    end
    
    it "sets rack.test to true in the env" do
      @session.request "/"
      request.env["rack.test"].should == true
    end
    
    it "defaults to port 80" do
      @session.request "/"
      request.env["SERVER_PORT"].should == "80"
    end
    
    it "defaults to example.org" do
      @session.request "/"
      request.env["SERVER_NAME"].should == "example.org"
    end
    
    it "keeps a cookie jar" do
      @session.request "/set-cookie"
      response.body.should == ["Value: 0"]
      @session.request "/set-cookie"
      response.body.should == ["Value: 1"]
    end
    
    it "accepts explicitly provided cookies" do
      @session.request "/set-cookie", :cookie => "value=1"
      response.body.should == ["Value: 1"]
    end
    
    it "sends multipart requests"
    
    it "yields the response to a given block" do
      @session.request "/" do |response|
        response.should be_ok
      end
    end
    
    context "when input is given" do
      it "should send the input" do
        @session.request "/", :method => "POST", :input => "foo"
        request.env["rack.input"].string.should == "foo"
      end
      
      it "should not send a multipart request" do
        @session.request "/", :method => "POST", :input => "foo"
        request.env["CONTENT_TYPE"].should_not == "application/x-www-form-urlencoded"
      end
    end
    
    context "for a POST" do
      it "uses application/x-www-form-urlencoded as the CONTENT_TYPE" do
        @session.request "/", :method => "POST"
        request.env["CONTENT_TYPE"].should == "application/x-www-form-urlencoded"
      end
    end
    
    describe "#before_request" do
      it "is called before each request" do
        req = nil

        @session.before_request do |request|
          req = request
        end

        @session.request "/"
        req.should_not be_nil
      end

      it "is called in the order callbacks are added" do
        callbacks_called = []

        @session.before_request do
          callbacks_called << :first
        end

        @session.before_request do
          callbacks_called << :second
        end

        @session.request "/"
        callbacks_called.should == [:first, :second]
      end

      it "accepts callbacks that don't accept paramters" do
        value = false
        @session.before_request do
          value = true
        end

        @session.request "/"
        value.should be_true
      end
    end
    
    describe "#after_request" do
      it "is called after each request" do
        resp = nil

        @session.after_request do |response|
          resp = response
        end

        @session.request "/"
        resp.should_not be_nil
      end
      
      it "is called in the order callbacks are added" do
        callbacks_called = []

        @session.after_request do
          callbacks_called << :first
        end

        @session.after_request do
          callbacks_called << :second
        end

        @session.request "/"
        callbacks_called.should == [:first, :second]
      end
      
      it "accepts callbacks that don't accept paramters" do
        value = false
        @session.after_request do
          value = true
        end

        @session.request "/"
        value.should be_true
      end
    end
    
    context "when the URL is https://" do
      it "sets SERVER_PORT to 443" do
        @session.get "https://example.org/"
        request.env["SERVER_PORT"].should == "443"
      end
      
      it "sets HTTPS to on" do
        @session.get "https://example.org/"
        request.env["HTTPS"].should == "on"
      end
    end
  end

  describe "#initialize" do
    it "raises ArgumentError if the given app doesn't quack like an app" do
      lambda {
        Rack::Test::Session.new(Object.new)
      }.should raise_error(ArgumentError)
    end
  end

  describe "#last_request" do
    it "returns the most recent request" do
      @session.request "/"
      @session.last_request.env["PATH_INFO"].should == "/"
    end
    
    it "raises an error if no requests have been issued" do
      lambda {
        @session.last_request
      }.should raise_error
    end
  end
  
  describe "#last_response" do
    it "returns the most recent response" do
      @session.request "/"
      @session.last_response["Content-Type"].should == "text/html"
    end
    
    it "raises an error if no requests have been issued" do
      lambda {
        @session.last_response
      }.should raise_error
    end
  end
  
  describe "#get" do
    it "requests the URL using GET" do
      @session.get "/"
      request.env["REQUEST_METHOD"].should == "GET"
      response.should be_ok
    end

    it "uses the provided params hash" do
      @session.get "/", :foo => "bar"
      request.GET.should == { "foo" => "bar" }
    end
    
    it 'accepts params in the path' do
      @session.get "/?foo=bar"
      request.GET.should == { "foo" => "bar" }
    end
    
    it "uses the provided env" do
      @session.get "/", {}, { "User-Agent" => "Rack::Test" }
      request.env["User-Agent"].should == "Rack::Test"
    end
  end

  describe "#head" do
    it "requests the URL using HEAD" do
      @session.head "/"
      request.env["REQUEST_METHOD"].should == "HEAD"
      response.should be_ok
    end
    
    it "accepts a params hash" do
      @session.head "/", :foo => "bar"
      request.GET.should == { "foo" => "bar" }
    end
    
    it 'returns an empty body' do
      @session.head "/"
      response.body.should == []
    end
    
    it "uses the provided env" do
      @session.head "/", {}, { "X-Foo" => "bar" }
      request.env["X-Foo"].should == "bar"
    end
  end
  
  describe "#post" do
    it "requests the URL using POST" do
      @session.post "/"
      request.env["REQUEST_METHOD"].should == "POST"
      response.should be_ok
    end
    
    it "uses application/x-www-form-urlencoded as the CONTENT_TYPE" do
      @session.post "/"
      request.env["CONTENT_TYPE"].should == "application/x-www-form-urlencoded"
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
    it "requests the URL using PUT" do
      @session.put "/"
      request.env["REQUEST_METHOD"].should == "PUT"
      response.should be_ok
    end
    
    it "uses the provided params hash" do
      @session.put "/", "param" => "param value"
      request.GET.should == { "param" => "param value" }
    end
    
    it "uses the provided env" do
      @session.put "/", {}, { "X-Foo" => "bar" }
      request.env["X-Foo"].should == "bar"
    end
  end
  
  describe "#delete" do
    it "requests the URL using DELETE" do
      @session.delete "/"
      request.env["REQUEST_METHOD"].should == "DELETE"
      response.should be_ok
    end
    
    it "uses the provided params hash" do
      @session.delete "/", "param" => "param value"
      request.GET.should == { "param" => "param value" }
    end
    
    it "uses the provided env" do
      @session.delete "/", {}, { "X-Foo" => "bar" }
      request.env["X-Foo"].should == "bar"
    end
  end

  describe "#head" do
    it "requests the URL using DELETE"
    it "uses the provided params hash"
    it "uses the provided env"
    it "resets the body"
  end
end
