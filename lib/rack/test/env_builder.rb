module Rack
  module Test
    class EnvBuilder
      include Rack::Test::Utils

      def initialize(env, uri)
        @env = env
        @uri = uri
      end

      def hash(session)
        env["HTTP_HOST"] ||= host_from_uri
        env["HTTP_X_REQUESTED_WITH"] = "XMLHttpRequest" if env[:xhr]
        env["HTTPS"] = "on" if uri.is_a?(URI::HTTPS)

        # TODO: Remove this after Rack 1.1 has been released.
        # Stringifying and upcasing methods has be commit upstream
        env["REQUEST_METHOD"] ||= env[:method] ? env[:method].to_s.upcase : "GET"

        handle_params

        if env.has_key?(:cookie)
          session.set_cookie(env.delete(:cookie), uri)
        end

        Rack::MockRequest.env_for(uri.to_s, env)
      end

      private

      attr_reader :env, :uri

      def host_from_uri
        [uri.host, (uri.port unless uri.port == uri.default_port)].compact.join(":")
      end

      def handle_params
        params = env.delete(:params)

        if env["REQUEST_METHOD"] == "GET"
          merge_into_query_string(params) if params
        elsif !env.has_key?(:input)
          set_body_from(params)
        end
      end

      def merge_into_query_string(params)
        params = parse_nested_query(params) if params.is_a?(String)
        params.merge!(parse_nested_query(uri.query))

        uri.query = build_nested_query(params)
      end

      def set_body_from(params)
        env["CONTENT_TYPE"] ||= "application/x-www-form-urlencoded"

        if params.is_a?(Hash)
          if body = build_multipart(params)
            env[:input] = body
            env["CONTENT_LENGTH"] ||= body.length.to_s
            env["CONTENT_TYPE"] = "multipart/form-data; boundary=#{MULTIPART_BOUNDARY}"
          else
            env[:input] = params_to_string(params)
          end
        else
          env[:input] = params
        end
      end

      def params_to_string(params)
        case params
        when Hash then build_nested_query(params)
        when nil  then ""
        else params
        end
      end
    end
  end
end
