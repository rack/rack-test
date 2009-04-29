module Rack
  
  class MockSession
    attr_writer :cookie_jar
    attr_reader :last_response
    
    def initialize(app)
      @app = app
    end
    
    def clear_cookies
      @cookie_jar = Rack::Test::CookieJar.new
    end
    
    def set_cookie(cookie, uri = nil)
      @cookie_jar = cookie_jar.merge(cookie, uri)
    end
    
    def request(uri, env)
      env["HTTP_COOKIE"] ||= cookie_jar.for(uri)
      @last_request = Rack::Request.new(env)
      status, headers, body = @app.call(@last_request.env)
      @last_response = MockResponse.new(status, headers, body, env["rack.errors"])
      @cookie_jar = cookie_jar.merge(last_response.headers["Set-Cookie"], uri)
      
      return @last_response
    end
    
    # Return the last request issued in the session. Raises an error if no
    # requests have been sent yet.
    def last_request
      raise Rack::Test::Error.new("No request yet. Request a page first.") unless @last_request
      @last_request
    end
    
    # Return the last response received in the session. Raises an error if
    # no requests have been sent yet.
    def last_response
      raise Rack::Test::Error.new("No response yet. Request a page first.") unless @last_response
      @last_response
    end

  protected
  
    def cookie_jar
      @cookie_jar ||= Rack::Test::CookieJar.new
    end
    
  end
  
end