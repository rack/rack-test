require_relative '../../spec_helper'

describe "Rack::Test::Utils#build_nested_query" do
  include Rack::Test::Utils

  it 'converts empty strings to =' do
    build_nested_query('').must_equal '='
  end

  it 'converts nil to an empty string' do
    build_nested_query(nil).must_equal ''
  end

  it 'converts hashes with nil values' do
    build_nested_query(a: nil).must_equal 'a'
  end

  it 'converts hashes' do
    build_nested_query(a: 1).must_equal 'a=1'
  end

  it 'converts hashes with multiple keys' do
    hash = { a: 1, b: 2 }
    build_nested_query(hash).must_equal 'a=1&b=2'
  end

  it 'converts empty arrays' do
    build_nested_query(a: []).must_equal 'a[]='
  end

  it 'converts arrays with one element' do
    build_nested_query(a: [1]).must_equal 'a[]=1'
  end

  it 'converts arrays with multiple elements' do
    build_nested_query(a: [1, 2]).must_equal 'a[]=1&a[]=2'
  end

  it "converts arrays with brackets '[]' in the name" do
    build_nested_query('a[]' => [1, 2]).must_equal 'a%5B%5D=1&a%5B%5D=2'
  end

  it 'converts nested hashes' do
    build_nested_query(a: { b: 1 }).must_equal 'a[b]=1'
  end

  it 'converts arrays nested in a hash' do
    build_nested_query(a: { b: [1, 2] }).must_equal 'a[b][]=1&a[b][]=2'
  end

  it 'converts arrays of hashes' do
    build_nested_query(a: [{ b: 2 }, { c: 3 }]).must_equal 'a[][b]=2&a[][c]=3'
  end

  it 'supports hash keys with empty arrays' do
    input = { collection: [] }
    build_nested_query(input).must_equal 'collection[]='
  end
end

describe 'Rack::Test::Utils.build_multipart' do
  include Rack::Test::Utils

  it 'builds multipart bodies' do
    files = Rack::Test::UploadedFile.new(multipart_file('foo.txt'))
    data  = Rack::Test::Utils.build_multipart('submit-name' => 'Larry', 'files' => files)

    options = {
      'CONTENT_TYPE' => "multipart/form-data; boundary=#{Rack::Test::MULTIPART_BOUNDARY}",
      'CONTENT_LENGTH' => data.length.to_s,
      :input => StringIO.new(data)
    }
    env = Rack::MockRequest.env_for('/', options)
    params = Rack::Multipart.parse_multipart(env)
    params['submit-name'].must_equal 'Larry'
    params['files'][:filename].must_equal 'foo.txt'
    files.pos.must_equal 0
    params['files'][:tempfile].read.must_equal files.read
  end

  it 'handles uploaded files not responding to set_encoding as empty' do
    # Capybara::RackTest::Form::NilUploadedFile
    c = Class.new(Rack::Test::UploadedFile) do
      def initialize
        @empty_file = Tempfile.new('nil_uploaded_file')
        @empty_file.close
      end

      def original_filename; ''; end
      def content_type; 'application/octet-stream'; end
      def path; @empty_file.path; end
      def size; 0; end
      def read; ''; end
      def respond_to?(m, *a)
        return false if m == :set_encoding
        super(m, *a)
      end
    end

    data  = Rack::Test::Utils.build_multipart('submit-name' => 'Larry', 'files' => c.new)
    options = {
      'CONTENT_TYPE' => "multipart/form-data; boundary=#{Rack::Test::MULTIPART_BOUNDARY}",
      'CONTENT_LENGTH' => data.length.to_s,
      :input => StringIO.new(data)
    }
    env = Rack::MockRequest.env_for('/', options)
    params = Rack::Multipart.parse_multipart(env)
    params['submit-name'].must_equal 'Larry'
    params['files'].must_be_nil
    data.must_include 'content-disposition: form-data; name="files"; filename=""'
    data.must_include 'content-length: 0'
  end

  it 'builds multipart bodies from array of files' do
    files = [Rack::Test::UploadedFile.new(multipart_file('foo.txt')), Rack::Test::UploadedFile.new(multipart_file('bar.txt'))]
    data = Rack::Test::Utils.build_multipart('submit-name' => 'Larry', 'files' => files)

    options = {
      'CONTENT_TYPE' => "multipart/form-data; boundary=#{Rack::Test::MULTIPART_BOUNDARY}",
      'CONTENT_LENGTH' => data.length.to_s,
      :input => StringIO.new(data)
    }
    env = Rack::MockRequest.env_for('/', options)
    params = Rack::Multipart.parse_multipart(env)
    params['submit-name'].must_equal 'Larry'

    params['files'][0][:filename].must_equal 'foo.txt'
    params['files'][0][:tempfile].read.must_equal "bar\n"

    params['files'][1][:filename].must_equal 'bar.txt'
    params['files'][1][:tempfile].read.must_equal "baz\n"
  end

  it 'builds multipart bodies from mixed array of a file and a primitive' do
    files = [Rack::Test::UploadedFile.new(multipart_file('foo.txt')), 'baz']
    data = Rack::Test::Utils.build_multipart('files' => files)

    options = {
      'CONTENT_TYPE' => "multipart/form-data; boundary=#{Rack::Test::MULTIPART_BOUNDARY}",
      'CONTENT_LENGTH' => data.length.to_s,
      :input => StringIO.new(data)
    }
    env = Rack::MockRequest.env_for('/', options)
    params = Rack::Multipart.parse_multipart(env)

    params['files'][0][:filename].must_equal 'foo.txt'
    params['files'][0][:tempfile].read.must_equal "bar\n"

    params['files'][1].must_equal 'baz'
  end

  it 'builds nested multipart bodies' do
    files = Rack::Test::UploadedFile.new(multipart_file('foo.txt'))
    data  = Rack::Test::Utils.build_multipart('people' => [{ 'submit-name' => 'Larry', 'files' => files }], 'foo' => %w[1 2])

    options = {
      'CONTENT_TYPE' => "multipart/form-data; boundary=#{Rack::Test::MULTIPART_BOUNDARY}",
      'CONTENT_LENGTH' => data.length.to_s,
      :input => StringIO.new(data)
    }
    env = Rack::MockRequest.env_for('/', options)
    params = Rack::Multipart.parse_multipart(env)
    params['people'][0]['submit-name'].must_equal 'Larry'
    params['people'][0]['files'][:filename].must_equal 'foo.txt'
    params['people'][0]['files'][:tempfile].read.must_equal "bar\n"
    params['foo'].must_equal %w[1 2]
  end

  it 'builds nested multipart bodies with an array of hashes' do
    files = Rack::Test::UploadedFile.new(multipart_file('foo.txt'))
    data  = Rack::Test::Utils.build_multipart('files' => files, 'foo' => [{ 'id' => '1', 'name' => 'Dave' }, { 'id' => '2', 'name' => 'Steve' }])

    options = {
      'CONTENT_TYPE' => "multipart/form-data; boundary=#{Rack::Test::MULTIPART_BOUNDARY}",
      'CONTENT_LENGTH' => data.length.to_s,
      :input => StringIO.new(data)
    }
    env = Rack::MockRequest.env_for('/', options)
    params = Rack::Multipart.parse_multipart(env)
    params['files'][:filename].must_equal 'foo.txt'
    params['files'][:tempfile].read.must_equal "bar\n"
    params['foo'].must_equal [{ 'id' => '1', 'name' => 'Dave' }, { 'id' => '2', 'name' => 'Steve' }]
  end

  it 'builds nested multipart bodies with arbitrarily nested array of hashes' do
    files = Rack::Test::UploadedFile.new(multipart_file('foo.txt'))
    data  = Rack::Test::Utils.build_multipart('files' => files, 'foo' => { 'bar' => [{ 'id' => '1', 'name' => 'Dave' },
                                                                                     { 'id' => '2', 'name' => 'Steve', 'qux' => [{ 'id' => '3', 'name' => 'mike' },
                                                                                                                                 { 'id' => '4', 'name' => 'Joan' }] }] })

    options = {
      'CONTENT_TYPE' => "multipart/form-data; boundary=#{Rack::Test::MULTIPART_BOUNDARY}",
      'CONTENT_LENGTH' => data.length.to_s,
      :input => StringIO.new(data)
    }
    env = Rack::MockRequest.env_for('/', options)
    params = Rack::Multipart.parse_multipart(env)
    params['files'][:filename].must_equal 'foo.txt'
    params['files'][:tempfile].read.must_equal "bar\n"
    params['foo'].must_equal 'bar' => [{ 'id' => '1', 'name' => 'Dave' },
                             { 'id' => '2', 'name' => 'Steve', 'qux' => [{ 'id' => '3', 'name' => 'mike' },
                             { 'id' => '4', 'name' => 'Joan' }] }]
  end

  it 'does not break with params that look nested, but are not' do
    files = Rack::Test::UploadedFile.new(multipart_file('foo.txt'))
    data  = Rack::Test::Utils.build_multipart('foo[]' => '1', 'bar[]' => { 'qux' => '2' }, 'files[]' => files)

    options = {
      'CONTENT_TYPE' => "multipart/form-data; boundary=#{Rack::Test::MULTIPART_BOUNDARY}",
      'CONTENT_LENGTH' => data.length.to_s,
      :input => StringIO.new(data)
    }
    env = Rack::MockRequest.env_for('/', options)
    params = Rack::Multipart.parse_multipart(env)
    params['files'][0][:filename].must_equal 'foo.txt'
    params['files'][0][:tempfile].read.must_equal "bar\n"
    params['foo'][0].must_equal '1'
    params['bar'][0].must_equal 'qux' => '2'
  end

  it 'allows for nested files' do
    files = Rack::Test::UploadedFile.new(multipart_file('foo.txt'))
    data  = Rack::Test::Utils.build_multipart('foo' => [{ 'id' => '1', 'data' => files },
                                                        { 'id' => '2', 'data' => %w[3 4] }])

    options = {
      'CONTENT_TYPE' => "multipart/form-data; boundary=#{Rack::Test::MULTIPART_BOUNDARY}",
      'CONTENT_LENGTH' => data.length.to_s,
      :input => StringIO.new(data)
    }
    env = Rack::MockRequest.env_for('/', options)
    params = Rack::Multipart.parse_multipart(env)
    params['foo'][0]['id'].must_equal '1'
    params['foo'][0]['data'][:filename].must_equal 'foo.txt'
    params['foo'][0]['data'][:tempfile].read.must_equal "bar\n"
    params['foo'][1].must_equal 'id' => '2', 'data' => %w[3 4]
  end

  it 'returns nil if no UploadedFiles were used' do
    Rack::Test::Utils.build_multipart('people' => [{ 'submit-name' => 'Larry', 'files' => 'contents' }]).must_be_nil
  end

  it 'allows for forcing multipart uploads even without a file' do
    data  = Rack::Test::Utils.build_multipart({'foo' => [{ 'id' => '2', 'data' => %w[3 4] }]}, true, true)

    options = {
      'CONTENT_TYPE' => "multipart/form-data; boundary=#{Rack::Test::MULTIPART_BOUNDARY}",
      'CONTENT_LENGTH' => data.length.to_s,
      :input => StringIO.new(data)
    }
    env = Rack::MockRequest.env_for('/', options)
    params = Rack::Multipart.parse_multipart(env)
    params['foo'][0].must_equal 'id' => '2', 'data' => %w[3 4]
  end

  it 'raises ArgumentErrors if params is not a Hash' do
    proc do
      Rack::Test::Utils.build_multipart('foo=bar')
    end.must_raise(ArgumentError, 'value must be a Hash')
  end

  def multipart_file(name)
    File.join(File.dirname(__FILE__), '..', '..', 'fixtures', name.to_s)
  end
end
