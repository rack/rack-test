require "rubygems"
require "uri"
require "rack"

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
          def #{http_method}(path, params = {}, env = {})         # def get(path, params = {}, env = {})
            env = env_for(path,                                   #   env = env_for(path,
              env.merge(:method => "#{http_method.to_s.upcase}",  #     env.merge(:method => "GET",
              :params => params))                                 #     :params => params))
            process_request(env)                                  #   process_request(env)
          end                                                     # end
        SRC
      end

      def request(uri, env = {})
        env = Rack::MockRequest.env_for(uri.to_s, env)
        process_request(env)
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

      def process_request(env)
        env.update("rack.test" => true)
        @last_request = Rack::Request.new(env)
        
        @before_request.each do |before_request|
          before_request.call(@last_request)
        end
        
        status, headers, body = @app.call(@last_request.env)
        @last_response = Rack::Response.new(body, status, headers)
        
        @after_request.each do |after_request|
          after_request.call(@last_response)
        end
        
        return @last_response
      end
      
      def env_for(path, env)
        uri = URI.parse(path)

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
        
        if env[:params]
          uri.query = param_string(env.delete(:params))
        end

        Rack::MockRequest.env_for(uri.to_s, env)
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
