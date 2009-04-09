require "rubygems"

unless $LOAD_PATH.include?(File.expand_path(File.dirname(__FILE__) + "/.."))
  $LOAD_PATH.unshift(File.expand_path(File.dirname(__FILE__) + "/.."))
end

require "uri"
require "rack"
require "rack/test/cookie_jar"
require "rack/test/utils"
require "rack/test/methods"
require "rack/test/uploaded_file"

module Rack
  module Test

    VERSION = "0.1.0"

    MULTIPART_BOUNDARY = "----------XnJLe9ZIbbGUYtzPQJ16u1"
    
    # The common base class for exceptions raised by Rack::Test
    class Error < StandardError
    end

    class Session
      include Rack::Test::Utils

      # Initialize a new session for the given Rack app
      def initialize(app)
        raise ArgumentError.new("app must respond_to?(:call)") unless app.respond_to?(:call)

        @headers = {}
        @app = app
      end

      # Issue a GET request for the given URI with the given params and Rack
      # environment. Stores the issues request object in #last_request and
      # the app's response in #last_response. Yield #last_response to a block
      # if given.
      #
      # Example:
      #   get "/"
      def get(uri, params = {}, env = {}, &block)
        env = env_for(uri, env.merge(:method => "GET", :params => params))
        process_request(uri, env, &block)
      end

      # Issue a POST request for the given URI. See #get
      #
      # Example:
      #   post "/signup", "name" => "Bryan"
      def post(uri, params = {}, env = {}, &block)
        env = env_for(uri, env.merge(:method => "POST", :params => params))
        process_request(uri, env, &block)
      end

      # Issue a PUT request for the given URI. See #get
      #
      # Example:
      #   put "/"
      def put(uri, params = {}, env = {}, &block)
        env = env_for(uri, env.merge(:method => "PUT", :params => params))
        process_request(uri, env, &block)
      end

      # Issue a DELETE request for the given URI. See #get
      #
      # Example:
      #   delete "/"
      def delete(uri, params = {}, env = {}, &block)
        env = env_for(uri, env.merge(:method => "DELETE", :params => params))
        process_request(uri, env, &block)
      end

      # Issue a HEAD request for the given URI. See #get
      #
      # Example:
      #   head "/"
      def head(uri, params = {}, env = {}, &block)
        env = env_for(uri, env.merge(:method => "HEAD", :params => params))
        process_request(uri, env, &block)
      end

      # Issue a request to the Rack app for the given URI and optional Rack
      # environment. Stores the issues request object in #last_request and
      # the app's response in #last_response. Yield #last_response to a block
      # if given.
      #
      # Example:
      #   request "/"
      def request(uri, env = {}, &block)
        env = env_for(uri, env)
        process_request(uri, env, &block)
      end

      # Set a header to be included on all subsequent requests through the
      # session. Use a value of nil to remove a previously configured header.
      #
      # Example:
      #   header "User-Agent", "Firefox"
      def header(name, value)
        if value.nil?
          @headers.delete(name)
        else
          @headers[name] = value
        end
      end

      # Set the username and password for HTTP Basic authorization, to be
      # included in subsequent requests in the HTTP_AUTHORIZATION header.
      #
      # Example:
      #   authorize "bryan", "secret"
      def authorize(username, password)
        encoded_login = ["#{username}:#{password}"].pack("m*")
        header('HTTP_AUTHORIZATION', "Basic #{encoded_login}")
      end

      # Rack::Test will not follow any redirects automatically. This method
      # will follow the redirect returned in the last response. If the last
      # response was not a redirect, an error will be raised.
      def follow_redirect!
        unless last_response.redirect?
          raise Error.new("Last response was not a redirect. Cannot follow_redirect!")
        end

        get(last_response["Location"])
      end

      # Return the last request issued in the session. Raises an error if no
      # requests have been sent yet.
      def last_request
        raise Error.new("No request yet. Request a page first.") unless @last_request

        @last_request
      end

      # Return the last response received in the session. Raises an error if
      # no requests have been sent yet.
      def last_response
        raise Error.new("No response yet. Request a page first.") unless @last_response

        @last_response
      end

    private


      def env_for(path, env)
        uri = URI.parse(path)
        uri.host ||= "example.org"

        env = default_env.merge(env)

        if URI::HTTPS === uri
          env.update("HTTPS" => "on")
        end

        if env[:xhr]
          env["X-Requested-With"] = "XMLHttpRequest"
        end

        if (env[:method] == "POST" || env["REQUEST_METHOD"] == "POST") && !env.has_key?(:input)
          env["CONTENT_TYPE"] = "application/x-www-form-urlencoded"
          
          multipart = (env[:params] || {}).any? do |k, v|
            UploadedFile === v
          end
          
          if multipart
            env[:input] = multipart_body(env.delete(:params))
            env["CONTENT_LENGTH"] ||= env[:input].length.to_s
            env["CONTENT_TYPE"] = "multipart/form-data; boundary=#{MULTIPART_BOUNDARY}"
          else
            env[:input] = params_to_string(env.delete(:params))
          end
        end

        params = env[:params] || {}
        params.update(parse_query(uri.query))
        
        uri.query = requestify(params)

        if env.has_key?(:cookie)
          # Add the cookies explicitly set by the user
          env["HTTP_COOKIE"] = cookie_jar.merge(uri, env.delete(:cookie)).for(uri)
        else
          env["HTTP_COOKIE"] = cookie_jar.for(uri)
        end

        Rack::MockRequest.env_for(uri.to_s, env)
      end

      def cookie_jar
        @cookie_jar || Rack::Test::CookieJar.new
      end

      def process_request(uri, env)
        uri = URI.parse(uri)
        uri.host ||= "example.org"

        @last_request = Rack::Request.new(env)

        status, headers, body = @app.call(@last_request.env)
        @last_response = MockResponse.new(status, headers, body, env['rack.errors'])

        @cookie_jar = cookie_jar.merge(uri, last_response.headers["Set-Cookie"])

        yield @last_response if block_given?

        @last_response
      end

      def default_env
        { "rack.test" => true, "REMOTE_ADDR" => "127.0.0.1" }.merge(@headers)
      end
      
      def params_to_string(params)
        case params
        when Hash then requestify(params)
        when nil  then ""
        else params
        end
      end

    end

  end
end
