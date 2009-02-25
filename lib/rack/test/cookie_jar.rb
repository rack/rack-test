module Rack
  module Test

    class Cookie
      include Rack::Utils

      # :api: private
      attr_reader :name, :value

      # :api: private
      def initialize(raw, default_host)
        # separate the name / value pair from the cookie options
        @name_value_raw, options = raw.split(/[;,] */n, 2)

        @name, @value = parse_query(@name_value_raw, ';').to_a.first
        @options = parse_query(options, ';')

        @options.delete_if { |k, v| !v || v.empty? }

        @options["domain"] ||= default_host
      end

      # :api: private
      def raw
        @name_value_raw
      end

      # :api: private
      def empty?
        @value.nil? || @value.empty?
      end

      # :api: private
      def domain
        @options["domain"]
      end

      # :api: private
      def path
        @options["path"] || "/"
      end

      # :api: private
      def expires
        Time.parse(@options["expires"]) if @options["expires"]
      end

      # :api: private
      def expired?
        expires && expires < Time.now
      end

      # :api: private
      def valid?(uri)
        uri.host =~ Regexp.new("#{Regexp.escape(domain)}$") &&
        uri.path =~ Regexp.new("^#{Regexp.escape(path)}")
      end

      # :api: private
      def matches?(uri)
        ! expired? && valid?(uri)
      end

      # :api: private
      def <=>(other)
        # Orders the cookies from least specific to most
        [name, path, domain.reverse] <=> [other.name, other.path, other.domain.reverse]
      end

    end

    class CookieJar

      # :api: private
      def initialize(cookies = [])
        @jar = cookies
        @jar.sort!
      end

      def merge(uri, raw_cookies)
        return self unless raw_cookies

        # Initialize all the the received cookies
        cookies = []
        raw_cookies.each do |raw|
          c = Cookie.new(raw, uri.host)
          cookies << c if c.valid?(uri)
        end

        # Remove all the cookies that will be updated
        new_jar = @jar.reject do |existing|
          cookies.find do |c|
            [c.name, c.domain, c.path] == [existing.name, existing.domain, existing.path]
          end
        end

        new_jar.concat cookies

        return self.class.new(new_jar)
      end

      # :api: private
      def for(uri)
        cookies = {}

        # The cookies are sorted by most specific first. So, we loop through
        # all the cookies in order and add it to a hash by cookie name if
        # the cookie can be sent to the current URI. It's added to the hash
        # so that when we are done, the cookies will be unique by name and
        # we'll have grabbed the most specific to the URI.
        @jar.each do |cookie|
          cookies[cookie.name] = cookie.raw if cookie.matches?(uri)
        end

        cookies.values.join(';')
      end

    end

  end
end
