require "rubygems"
require "uri"
require "rack"

require File.dirname(__FILE__) + "/test/cookie_jar"

module Rack
  module Test
    class Session
      include Rack::Utils

      def initialize(app)
        @app = app
        
        @before_request = []
        @after_request = []
      end

      [:get, :post, :put, :delete].each do |http_method|
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
      end
      
      def before_request(&block)
        @before_request << block
      end
      
      def after_request(&block)
        @after_request << block
      end
      
      def last_request
        raise unless @last_request
        return @last_request
      end
      
      def last_response
        raise unless @last_response
        return @last_response
      end
      
      alias_method :response, :last_response
      
    private

      def cookie_jar
        @cookie_jar ||= Rack::Test::CookieJar.new
      end
      
      def process_request(uri, env)
        uri = URI.parse(uri)
        uri.host ||= "example.org"
        
        if env[:params]
          uri.query = param_string(env.delete(:params))
        end
        
        if env.has_key?(:cookie)
          # Add the cookies explicitly set by the user
          cookie_jar.update(uri, env.delete(:cookie))
        end
        
        env["HTTP_COOKIE"] = cookie_jar.for(uri)
        
        env = Rack::MockRequest.env_for(uri.to_s, env)
        @last_request = Rack::Request.new(env)
        
        execute_callbacks(@before_request, @last_request)
        
        status, headers, body = @app.call(@last_request.env)
        @last_response = Rack::Response.new(body, status, headers)
        cookie_jar.update(uri, last_response.headers["Set-Cookie"])
        
        execute_callbacks(@after_request, @last_response)
        
        return @last_response
      end
      
      def execute_callbacks(callbacks, param)
        callbacks.each do |callback|
          callback.call(param)
        end
      end
      
      def env_for(path, env)
        uri = URI.parse(path)
        
        env.update("rack.test" => true)
        
        if URI::HTTPS === uri
          env.update("HTTPS" => "on")
        end
        
        if (env[:method] == "POST" || env["REQUEST_METHOD"] == "POST")
          env["Content-Type"] = "application/x-www-form-urlencoded"
          params = env.delete(:params)
          
          if params.is_a?(Hash)
            env[:input] = param_string(params)
          else
            env[:input] = params
          end
        end
        
        return env
      end

      def param_string(value, prefix = nil)
        case value
        when Array
          value.map { |v|
            param_string(v, "#{prefix}[]")
          } * "&"
        when Hash
          value.map { |k, v|
            param_string(v, prefix ? "#{prefix}[#{escape(k)}]" : escape(k))
          } * "&"
        else
          "#{prefix}=#{escape(value)}"
        end
      end
      
    end
  end
end
