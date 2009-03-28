module Rack
  module Test

    module Utils
      include Rack::Utils

      def requestify(value, prefix = nil)
        case value
        when Array
          value.map do |v|
            requestify(v, "#{prefix}[]")
          end.join("&")
        when Hash
          value.map do |k, v|
            requestify(v, prefix ? "#{prefix}[#{escape(k)}]" : escape(k))
          end.join("&")
        else
          "#{prefix}=#{escape(value)}"
        end
      end

      module_function :requestify

    end

  end
end
