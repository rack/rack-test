require "rubygems"

unless $LOAD_PATH.include?(File.expand_path(File.dirname(__FILE__) + "/.."))
  $LOAD_PATH.unshift(File.expand_path(File.dirname(__FILE__) + "/.."))
end

require "uri"
require "rack"
require "rack/test/cookie_jar"
require "rack/test/utils"
require "rack/test/methods"

module Rack
  module Test
    
    VERSION = "0.1.0"
    
    # The common base class for exceptions raised by Rack::Test
    class Error < StandardError
    end
    
    class Session
      include Rack::Test::Utils

      def initialize(app)
        raise ArgumentError.new("app must respond_to?(:call)") unless app.respond_to?(:call)

        @headers = {}
        @app = app
      end

      [:get, :post, :put, :delete, :head].each do |http_method|
        class_eval <<-SRC
          def #{http_method}(uri, params = {}, env = {})          # def get(uri, params = {}, env = {})
            env = env_for(uri,                                    #   env = env_for(uri,
              env.merge(:method => "#{http_method.to_s.upcase}",  #     env.merge(:method => "GET",
              :params => params))                                 #     :params => params))
            process_request(uri, env)                             #   process_request(uri, env)
          end                                                     # end
        SRC
      end

      def request(uri, env = {})
        env = env_for(uri, env)
        process_request(uri, env)

        yield @last_response if block_given?

        @last_response
      end

      def header(name, value)
        if value.nil?
          @headers.delete(name)
        else
          @headers[name] = value
        end
      end
      
      def authorize(username, password)
        encoded_login = ["#{username}:#{password}"].pack("m*")
        header('HTTP_AUTHORIZATION', "Basic #{encoded_login}")
      end
      
      def follow_redirect!
        unless last_response.redirect?
          raise Error.new("Last response was not a redirect. Cannot follow_redirect!")
        end
        
        get(last_response["Location"])
      end

      def last_request
        raise Error.new("No request yet. Request a page first.") unless @last_request

        @last_request
      end

      def last_response
        raise Error.new("No response yet. Request a page first.") unless @last_response

        @last_response
      end

      alias_method :response, :last_response

    private

      
      def env_for(path, env)
        uri = URI.parse(path)
        uri.host ||= "example.org"

        env = default_env.merge(env)

        if URI::HTTPS === uri
          env.update("HTTPS" => "on")
        end

        if (env[:method] == "POST" || env["REQUEST_METHOD"] == "POST") && !env.has_key?(:input)
          env["CONTENT_TYPE"] = "application/x-www-form-urlencoded"
          env[:input] = params_to_string(env.delete(:params))
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
        @last_response = Rack::Response.new(body, status, headers)
        @cookie_jar = cookie_jar.merge(uri, last_response.headers["Set-Cookie"])

        @last_response
      end

      def default_env
        {
          "rack.test"   => true,
          "REMOTE_ADDR" => "127.0.0.1"
        }.merge(@headers)
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
