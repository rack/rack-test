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
          when 'HEAD'
            return [200, {}, []]
          when 'OPTIONS'
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

        if path == '/redirected'
          additional_info = method == 'GET' ? ", session #{session.inspect} with options #{env['rack.session.options'].inspect}" : " using #{method.downcase} with #{params}"
          return [200, {}, ["You've been redirected" + additional_info]]
        end

        if path == '/void' && method == 'GET'
          return [200, {}, []]
        end

        if %w'/cookies/show /COOKIES/show /not-cookies/show /cookies/default-path'.include?(path) && method == 'GET'
          return [200, {}, [req.cookies.inspect]]
        end

        if path == '/cookies/set-secure' && method == 'GET'
          return [200, { 'Set-Cookie' => "secure-cookie=#{params['value'] || raise}; secure" }, ['Set']]
        end

        if (path == '/cookies/set-simple' && method == 'GET') || (path == '/cookies/default-path' && method == 'POST')
          return [200, { 'Set-Cookie' => "simple=#{params['value'] || raise};" }, ['Set']]
        end

        if path == '/cookies/delete' && method == 'GET'
          return [200, { 'Set-Cookie' => "value=; expires=#{Time.at(0)}" }, []]
        end

        if path == '/cookies/count' && method == 'GET'
          new_value = new_cookie_count(req)
          return [200, { 'Set-Cookie' => "count=#{new_value};" }, [new_value]]
        end

        if path == '/cookies/set' && method == 'GET'
          # expires: Time.now + 10)
          return [200, { 'Set-Cookie' => "value=#{params['value'] || raise}; path=/cookies; expires=#{Time.now+10}" }, ['Set']]
        end

        if path == '/cookies/domain' && method == 'GET'
          new_value = new_cookie_count(req)
          return [200, { 'Set-Cookie' => "count=#{new_value}; domain=localhost.com" }, [new_value]]
        end

        if path == '/cookies/subdomain' && method == 'GET'
          new_value = new_cookie_count(req)
          return [200, { 'Set-Cookie' => "count=#{new_value}; domain=.example.org" }, [new_value]]
        end

        if path == '/cookies/set-uppercase' && method == 'GET'
          return [200, { 'Set-Cookie' => "VALUE=#{params['value'] || raise}; path=/cookies; expires=#{Time.now+10}" }, ['Set']]
        end

        if path == '/cookies/set-multiple' && method == 'GET'
          return [200, { 'Set-Cookie' => "key1=value1\nkey2=value2"}, ['Set']]
        end

        return [404, {}, []]
      end
    end

    FAKE_APP = Rack::Lint.new(FakeApp.new.freeze)
  end
end
