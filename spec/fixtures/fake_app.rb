require 'time'
require 'rack/lint'

module Rack
  module Test
    class FakeApp
      def call(env)
        _, h, b = res = handle(env)
        length = 0
        b.each{|s| length += s.bytesize}
        h['content-length'] = length.to_s
        h['content-type'] = 'text/html;charset=utf-8'
        res
      end

      private

      def new_cookie_count(req)
        old_value = req.cookies['count'].to_i || 0
        (old_value + 1).to_s
      end

      def handle(env)
        method = env['REQUEST_METHOD']
        path = env['PATH_INFO']
        req = Rack::Request.new(env)
        params = req.params
        session = env['rack.session']

        if path == '/'
          case method
          when 'HEAD', 'OPTIONS'
            return [200, {}, []]
          else
            return [200, {}, ["Hello, #{method}: #{params.inspect}"]]
          end
        end

        if path == '/redirect' && method == 'GET'
          return [301, { 'location' => '/redirected' }, []]
        end

        if path == '/nested/redirect' && method == 'GET'
          return [301, { 'location' => 'redirected' }, []]
        end

        if path == '/nested/redirected' && method == 'GET'
          return [200, {}, ['Hello World!']]
        end

        if path == '/absolute/redirect' && method == 'GET'
          return [301, { 'location' => 'https://www.google.com' }, []]
        end

        if path == '/redirect' && method == 'POST'
          if params['status']
            return [Integer(params['status']), { 'location' => '/redirected' }, []]
          else
            return [302, { 'location' => '/redirected' }, []]
          end
        end

        if path == '/redirect-with-cookie' && method == 'GET'
          return [302, { 'set-cookie' => "value=1; path=/cookies;", 'location' => '/cookies/show' }, []]
        end

        if path == '/redirected'
          additional_info = if method == 'GET'
            ", session #{session.inspect} with options #{env['rack.session.options'].inspect}"
          else
            " using #{method.downcase} with #{params}"
          end
          return [200, {}, ["You've been redirected" + additional_info]]
        end

        if path == '/void' && method == 'GET'
          return [200, {}, []]
        end

        if %w[/cookies/show /COOKIES/show /not-cookies/show /cookies/default-path /cookies/default-path/sub].include?(path) && method == 'GET'
          return [200, {}, [req.cookies.inspect]]
        end

        if path == '/cookies/set-secure' && method == 'GET'
          return [200, { 'set-cookie' => "secure-cookie=#{params['value'] || raise}; secure" }, ['Set']]
        end

        if (path == '/cookies/set-simple' && method == 'GET') || (path == '/cookies/default-path' && method == 'POST')
          return [200, { 'set-cookie' => "simple=#{params['value'] || raise};" }, ['Set']]
        end

        if path == '/cookies/delete' && method == 'GET'
          return [200, { 'set-cookie' => "value=; expires=#{Time.at(0).httpdate}" }, []]
        end

        if path == '/cookies/count' && method == 'GET'
          new_value = new_cookie_count(req)
          return [200, { 'set-cookie' => "count=#{new_value};" }, [new_value]]
        end

        if path == '/cookies/set' && method == 'GET'
          return [200, { 'set-cookie' => "value=#{params['value'] || raise}; path=/cookies; expires=#{(Time.now+10).httpdate}" }, ['Set']]
        end

        if path == '/cookies/domain' && method == 'GET'
          new_value = new_cookie_count(req)
          return [200, { 'set-cookie' => "count=#{new_value}; domain=localhost.com" }, [new_value]]
        end

        if path == '/cookies/subdomain' && method == 'GET'
          new_value = new_cookie_count(req)
          return [200, { 'set-cookie' => "count=#{new_value}; domain=.example.org" }, [new_value]]
        end

        if path == '/cookies/set-uppercase' && method == 'GET'
          return [200, { 'set-cookie' => "VALUE=#{params['value'] || raise}; path=/cookies; expires=#{(Time.now+10).httpdate}" }, ['Set']]
        end

        if path == '/cookies/set-multiple' && method == 'GET'
          value = Rack.release >= '2.3' ? ["key1=value1", "key2=value2"] : "key1=value1\nkey2=value2"
          
          return [200, { 'set-cookie' => value }, ['Set']]
        end

        [404, {}, []]
      end
    end

    class InputRewinder
      def initialize(app)
        @app = app
      end

      def call(env)
        # Rack 3 removes the requirement for rewindable input.
        # Rack::Lint wraps the input and disallows direct access to rewind.
        # This breaks a lot of the specs that access last_request and
        # try to read the input. Work around this by reassigning the input
        # in env after the request, and rewinding it.
        input = env['rack.input']
        @app.call(env)
      ensure
        if input
          input.rewind
          env['rack.input'] = input
        end
      end
    end

    FAKE_APP = InputRewinder.new(Rack::Lint.new(FakeApp.new.freeze))
  end
end
