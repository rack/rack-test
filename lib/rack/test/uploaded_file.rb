require 'tempfile'
require 'fileutils'

module Rack
  module Test
    # Wraps a Tempfile with a content type. Including one or more UploadedFile's
    # in the params causes Rack::Test to build and issue a multipart request.
    #
    # Example:
    #   post "/photos", "file" => Rack::Test::UploadedFile.new("me.jpg", "image/jpeg")
    class UploadedFile
      # The filename, *not* including the path, of the "uploaded" file
      attr_reader :original_filename

      # The tempfile
      attr_reader :tempfile

      # The content type of the "uploaded" file
      attr_accessor :content_type

      def initialize(content, content_type = 'text/plain', binary = false, original_filename: nil)
        if content.respond_to?(:read)
          initialize_from_io(content, original_filename)
        else
          initialize_from_file_path(content)
        end
        @content_type = content_type
        @tempfile.binmode if binary
      end

      def path
        tempfile.path
      end

      alias local_path path

      def method_missing(method_name, *args, &block) #:nodoc:
        tempfile.public_send(method_name, *args, &block)
      end

      def respond_to_missing?(method_name, include_private = false) #:nodoc:
        tempfile.respond_to?(method_name, include_private) || super
      end

      def self.finalize(file)
        proc { actually_finalize file }
      end

      def self.actually_finalize(file)
        file.close
        file.unlink
      end

      private

      def initialize_from_io(io, original_filename)
        @tempfile = io
        @original_filename = original_filename || raise(ArgumentError, 'Missing `original_filename` for IO')
      end

      def initialize_from_file_path(path)
        raise "#{path} file does not exist" unless ::File.exist?(path)

        @original_filename = ::File.basename(path)

        @tempfile = Tempfile.new([@original_filename, ::File.extname(path)])
        @tempfile.set_encoding(Encoding::BINARY) if @tempfile.respond_to?(:set_encoding)

        ObjectSpace.define_finalizer(self, self.class.finalize(@tempfile))

        FileUtils.copy_file(path, @tempfile.path)
      end
    end
  end
end
