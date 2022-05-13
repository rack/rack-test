module Rack
  # The Rack::MockSession class is a lower-level session class used by
  # Rack::Test::Session.  It handles the cookies and issues requests
  # to the application.  It also supports running code after requests.
  class MockSession # :nodoc:
    # The Rack::Test::CookieJar for the cookies for the current session.
    attr_accessor :cookie_jar

    # The default host used for the session for when using paths for URIs.
    attr_reader :default_host

    def initialize(app, default_host = Rack::Test::DEFAULT_HOST)
      @app = app
      @after_request = []
      @default_host = default_host
      @last_request = nil
      @last_response = nil
      clear_cookies
    end

    # Run a block after the each request completes.
    def after_request(&block)
      @after_request << block
    end

    # Replace the current cookie jar with an empty cookie jar.
    def clear_cookies
      @cookie_jar = Rack::Test::CookieJar.new([], @default_host)
    end

    # Set a cookie in the current cookie jar.
    def set_cookie(cookie, uri = nil)
      cookie_jar.merge(cookie, uri)
    end

    # Issue a request to the application for the given URI/path and rack environment,
    # using the cookie jar to set the appropriate cookie entry in the rack environment.
    def request(uri, env)
      env['HTTP_COOKIE'] ||= cookie_jar.for(uri)
      @last_request = Rack::Request.new(env)
      status, headers, body = @app.call(env).to_a

      @last_response = MockResponse.new(status, headers, body, env['rack.errors'].flush)
      close_body(body)
      cookie_jar.merge(last_response.headers['set-cookie'], uri)
      @after_request.each(&:call)
      @last_response.finish
    end

    # Return the last request issued in the session. Raises an error if no
    # requests have been sent yet.
    def last_request
      raise Rack::Test::Error, 'No request yet. Request a page first.' unless @last_request
      @last_request
    end

    # Return the last response received in the session. Raises an error if
    # no requests have been sent yet.
    def last_response
      raise Rack::Test::Error, 'No response yet. Request a page first.' unless @last_response
      @last_response
    end

    private

    # :nocov:
    if !defined?(Rack::RELEASE) || Gem::Version.new(Rack::RELEASE) < Gem::Version.new('2.2.2')
      def close_body(body)
        body.close if body.respond_to?(:close)
      end
    # :nocov:
    else
      # close() gets called automatically in newer Rack versions.
      def close_body(body)
      end
    end
  end
end
