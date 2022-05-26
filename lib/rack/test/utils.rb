module Rack
  module Test
    module Utils # :nodoc:
      include Rack::Utils
      extend self

      # Build a query string for the given value and prefix. The value
      # can be an array or hash of parameters.
      def build_nested_query(value, prefix = nil)
        case value
        when Array
          if value.empty?
            "#{prefix}[]="
          else
            value.map do |v|
              prefix = "#{prefix}[]" unless unescape(prefix) =~ /\[\]$/
              build_nested_query(v, prefix.to_s)
            end.join('&')
          end
        when Hash
          value.map do |k, v|
            build_nested_query(v, prefix ? "#{prefix}[#{escape(k)}]" : escape(k))
          end.join('&')
        when NilClass
          prefix.to_s
        else
          "#{prefix}=#{escape(value)}"
        end
      end

      # Build a multipart body for the given params.
      def build_multipart(params, _first = true, multipart = false)
        raise ArgumentError, 'value must be a Hash' unless params.is_a?(Hash)

        unless multipart
          query = lambda { |value|
            case value
            when Array
              value.each(&query)
            when Hash
              value.values.each(&query)
            when UploadedFile
              multipart = true
            end
          }
          params.values.each(&query)
          return nil unless multipart
        end

        build_parts(_build_multipart(params, true))
      end

      private

      # Return a flattened hash of parameter values based on the given params.
      def _build_multipart(params, first=false)
        flattened_params = {}

        params.each do |key, value|
          k = first ? key.to_s : "[#{key}]"

          case value
          when Array
            value.map do |v|
              if v.is_a?(Hash)
                nested_params = {}
                _build_multipart(v).each do |subkey, subvalue|
                  nested_params[subkey] = subvalue
                end
                (flattened_params["#{k}[]"] ||= []) << nested_params
              else
                flattened_params["#{k}[]"] = value
              end
            end
          when Hash
            _build_multipart(value).each do |subkey, subvalue|
              flattened_params[k + subkey] = subvalue
            end
          else
            flattened_params[k] = value
          end
        end

        flattened_params
      end

      # Build the multipart content for uploading.
      def build_parts(parameters)
        get_parts(parameters).join + "--#{MULTIPART_BOUNDARY}--\r"
      end

      # Return the multipart fragment of the given parameters.
      def get_parts(parameters)
        parameters.map do |name, value|
          if name =~ /\[\]\Z/ && value.is_a?(Array) && value.all? { |v| v.is_a?(Hash) }
            value.map do |hash|
              new_value = {}
              hash.each { |k, v| new_value[name + k] = v }
              get_parts(new_value).join
            end.join
          else
            [value].flatten.map do |v|
              if v.respond_to?(:original_filename)
                build_file_part(name, v)
              else
                primitive_part = build_primitive_part(name, v)
                # :nocov:
                Rack::Test.encoding_aware_strings? ? primitive_part.force_encoding('BINARY') : primitive_part
                # :nocov:
              end
            end.join
          end
        end
      end

      # Return the multipart fragment for a parameter that isn't a file upload.
      def build_primitive_part(parameter_name, value)
        <<-EOF
--#{MULTIPART_BOUNDARY}\r
content-disposition: form-data; name="#{parameter_name}"\r
\r
#{value}\r
EOF
      end

      # Return the multipart fragment for a parameter that is a file upload.
      def build_file_part(parameter_name, uploaded_file)
        uploaded_file.set_encoding(Encoding::BINARY)
        buffer = String.new
        buffer << (<<-EOF)
--#{MULTIPART_BOUNDARY}\r
content-disposition: form-data; name="#{parameter_name}"; filename="#{escape_path(uploaded_file.original_filename)}"\r
content-type: #{uploaded_file.content_type}\r
content-length: #{uploaded_file.size}\r
\r
EOF
        uploaded_file.append_to(buffer)
        buffer << "\r\n"
      end
    end
  end
end
