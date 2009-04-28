require File.dirname(__FILE__) + "/../../spec_helper"

describe Rack::Test::Session do
  context "cookies" do
    it "doesn't send expired cookies" do
      get "/cookies/set", "value" => "1"
      now = Time.now
      Time.stub!(:now => now + 60)
      get "/cookies/show"
      last_request.cookies.should == {}
    end
    
    it "doesn't send cookies with the wrong domain" do
      get "http://www.example.com/cookies/set", "value" => "1"
      get "http://www.other.example/cookies/show"
      last_request.cookies.should == {}
    end
    
    it "doesn't send cookies with the wrong path" do
      get "/cookies/set", "value" => "1"
      get "/not-cookies/show"
      last_request.cookies.should == {}
    end
    
    it "treats domains case insensitively" do
      get "http://example.com/cookies/set", "value" => "1"
      get "http://EXAMPLE.COM/cookies/show"
      last_request.cookies.should == { "value" => "1" }
    end
    
    it "treats paths case sensitively" do
      get "/cookies/set", "value" => "1"
      get "/COOKIES/show"
      last_request.cookies.should == {}
    end
    
    it "prefers more specific cookies" do
      get "http://example.com/cookies/set",     "value" => "domain"
      get "http://sub.example.com/cookies/set", "value" => "sub"
      
      get "http://sub.example.com/cookies/show"
      last_request.cookies.should == { "value" => "sub" }
      
      get "http://example.com/cookies/show"
      last_request.cookies.should == { "value" => "domain" }
    end
    
    it "treats cookie names case insensitively" do
      get "/cookies/set", "value" => "lowercase"
      get "/cookies/set-uppercase", "value" => "UPPERCASE"
      get "/cookies/show"
      last_request.cookies.should == { "VALUE" => "UPPERCASE" }
    end
    
    it "defaults the domain to the request domain" do
      get "http://example.com/cookies/set-simple", "value" => "cookie"
      get "http://example.com/cookies/show"
      last_request.cookies.should == { "simple" => "cookie" }
      
      get "http://other.example/cookies/show"
      last_request.cookies.should == {}
    end
    
    it "defaults the domain to the request path up to the last slash" do
      get "/cookies/set-simple", "value" => "1"
      get "/not-cookies/show"
      last_request.cookies.should == {}
    end
    
    it "supports secure cookies" do
      get "https://example.com/cookies/set-secure", "value" => "set"
      get "http://example.com/cookies/show"
      last_request.cookies.should == {}
      
      get "https://example.com/cookies/show"
      last_request.cookies.should == { "secure-cookie" => "set" }
    end
    
    it "keeps a cookie jar" do
      get "/cookies/show"
      last_request.cookies.should == {}
      
      get "/cookies/set", "value" => "1"
      get "/cookies/show"
      last_request.cookies.should == { "value" => "1" }
    end
    
    it "allows cookies to be cleared" do
      get "/cookies/set", "value" => "1"
      clear_cookies
      get "/cookies/show"
      last_request.cookies.should == {}
    end
    
    it "allow cookies to be set" do
      set_cookie "value", "10"
      get "/cookies/show"
      last_request.cookies.should == { "value" => "10" }
    end

    it "accepts explicitly provided cookies" do
      request "/cookies/show", :cookie => "value=1"
      last_request.cookies.should == { "value" => "1" }
    end
  end
end
