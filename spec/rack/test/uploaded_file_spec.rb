require_relative '../../spec_helper'

describe Rack::Test::UploadedFile do
  def file_path
    File.dirname(__FILE__) + '/../../fixtures/foo.txt'
  end

  it 'returns an instance of `Rack::Test::UploadedFile`' do
    uploaded_file = Rack::Test::UploadedFile.new(file_path)

    uploaded_file.class.must_equal Rack::Test::UploadedFile
  end

  it 'responds to things that Tempfile responds to' do
    uploaded_file = Rack::Test::UploadedFile.new(file_path)

    Tempfile.public_instance_methods(false).each do |method|
      uploaded_file.must_respond_to method
    end
  end

  it "creates Tempfiles with original file's extension" do
    uploaded_file = Rack::Test::UploadedFile.new(file_path)

    File.extname(uploaded_file.path).must_equal '.txt'
  end

  it 'creates Tempfiles with a path that includes a single extension' do
    uploaded_file = Rack::Test::UploadedFile.new(file_path)

    regex = /foo#{Time.now.year}.*\.txt\Z/
    uploaded_file.path.must_match regex
  end

  it 'respects binary argument' do
    Rack::Test::UploadedFile.new(file_path, 'text/plain', true).tempfile.must_be :binmode?
    Rack::Test::UploadedFile.new(file_path, 'text/plain', false).tempfile.wont_be :binmode?
    Rack::Test::UploadedFile.new(file_path, 'text/plain').tempfile.wont_be :binmode?
  end

  it 'raises for invalid files' do
    proc{Rack::Test::UploadedFile.new('does_not_exist')}.must_raise RuntimeError
  end

  it 'finalizes on garbage collection' do
    finalized = false
    c = Class.new(Rack::Test::UploadedFile) do
      define_singleton_method(:actually_finalize) do |file|
        finalized = true
        super(file)
      end
    end

    if RUBY_PLATFORM == 'java'
      require 'java'
      java_import 'java.lang.System'

      50.times do |_i|
        c.new(file_path)
        System.gc
      end
    else
      c.new(file_path)
      GC.start
    end

    # Due to CRuby's conservative garbage collection, you can never guarantee
    # an object will be garbage collected, so this is a source of potential
    # nondeterministic failure
    finalized.must_equal true
  end if RUBY_VERSION >= '2.7' || RUBY_ENGINE != 'ruby'

  it '#initialize with an IO object sets the specified filename' do
    original_filename = 'content.txt'
    uploaded_file = Rack::Test::UploadedFile.new(StringIO.new('I am content'), original_filename: original_filename)
    uploaded_file.original_filename.must_equal original_filename
  end

  it '#initialize without an original filename raises an error' do
    proc { Rack::Test::UploadedFile.new(StringIO.new('I am content')) }.must_raise(ArgumentError, 'Missing `original_filename` for StringIO object')
  end
end
