require "rubygems"
require "uri"
require "rack"

module Rack
  module Test
    class Session
      include Rack::Utils

      attr_reader :last_response
      attr_reader :last_request

      alias_method :response, :last_response

      def initialize(app)
        @app = app
      end

      def get(path, data=nil, headers={})
        request(path, data, headers.merge(:verb => "GET"))
      end

      def post(path, data=nil, headers={})
        request(path, data, headers.merge(:verb => "POST"))
      end

      def request(path, data=nil, headers={})
        env = env_for(path, data, headers)
        
        @last_request  = Rack::Request.new(env)
        @last_response = Rack::Response.new(@app.call(env))
      end
      
    private

      def env_for(path, data, headers)
        verb = headers.delete(:verb)
        
        uri = URI(path)
        uri.query = param_string(data) if data.is_a?(Hash)
        options = { :method => verb }
        options.merge!(headers) if headers

        if data.is_a?(Hash)
          env = data.delete(:headers)

          if verb == "POST"
            options["Content-Type"] = "application/x-www-form-urlencoded"
            options[:input] = param_string(data)
          end
        end

        env = headers.delete(:headers) if headers.is_a?(Hash)
        options[:input] ||= data       if data.is_a?(String)
        options.merge!(env)            if env

        Rack::MockRequest.env_for(uri.to_s, options)
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
