# frozen-string-literal: true

require_relative '../../spec_helper'

uploaded_files = Module.new do
  def fixture_path(name)
    File.join(File.dirname(__FILE__), '..', '..', 'fixtures', name)
  end

  def first_test_file_path
    fixture_path('foo.txt')
  end

  def uploaded_file
    Rack::Test::UploadedFile.new(first_test_file_path)
  end
end

describe 'Rack::Test::Session uploading one file' do
  include uploaded_files

  it 'sends the multipart/form-data content type if no content type is specified' do
    post '/', 'photo' => uploaded_file
    last_request.env['CONTENT_TYPE'].must_include 'multipart/form-data;'
  end

  it 'sends multipart/related content type if it is explicitly specified' do
    post '/', { 'photo' => uploaded_file }, 'CONTENT_TYPE' => 'multipart/related'
    last_request.env['CONTENT_TYPE'].must_include 'multipart/related;'
  end

  it 'sends regular params' do
    post '/', 'photo' => uploaded_file, 'foo' => 'bar'
    last_request.POST['foo'].must_equal 'bar'
  end

  it 'sends nested params' do
    post '/', 'photo' => uploaded_file, 'foo' => { 'bar' => 'baz' }
    last_request.POST['foo']['bar'].must_equal 'baz'
  end

  it 'sends multiple nested params' do
    post '/', 'photo' => uploaded_file, 'foo' => { 'bar' => { 'baz' => 'bop' } }
    last_request.POST['foo']['bar']['baz'].must_equal 'bop'
  end

  it 'sends params with arrays' do
    post '/', 'photo' => uploaded_file, 'foo' => %w[1 2]
    last_request.POST['foo'].must_equal %w[1 2]
  end

  it 'sends params with encoding sensitive values' do
    post '/', 'photo' => uploaded_file, 'foo' => 'bar? baz'
    last_request.POST['foo'].must_equal 'bar? baz'
  end

  it 'sends params encoded as ISO-8859-1' do
    utf8 = "\u2603"
    post '/', 'photo' => uploaded_file, 'foo' => 'bar', 'utf8' => utf8
    last_request.POST['foo'].must_equal 'bar'

    expected_value = if Rack::Test.encoding_aware_strings?
      utf8
    else
      utf8.b
    end

    last_request.POST['utf8'].must_equal expected_value
  end

  it 'sends params with parens in names' do
    post '/', 'photo' => uploaded_file, 'foo(1i)' => 'bar'
    last_request.POST['foo(1i)'].must_equal 'bar'
  end

  it 'sends params with encoding sensitive names' do
    post '/', 'photo' => uploaded_file, 'foo bar' => 'baz'
    last_request.POST['foo bar'].must_equal 'baz'
  end

  it 'sends files with the filename' do
    post '/', 'photo' => uploaded_file
    last_request.POST['photo'][:filename].must_equal 'foo.txt'
  end

  it 'sends files with the text/plain MIME type by default' do
    post '/', 'photo' => uploaded_file
    last_request.POST['photo'][:type].must_equal 'text/plain'
  end

  it 'sends files with the right name' do
    post '/', 'photo' => uploaded_file
    last_request.POST['photo'][:name].must_equal 'photo'
  end

  it 'allows overriding the content type' do
    post '/', 'photo' => Rack::Test::UploadedFile.new(first_test_file_path, 'image/jpeg')
    last_request.POST['photo'][:type].must_equal 'image/jpeg'
  end

  it 'sends files with a content-length in the header' do
    post '/', 'photo' => uploaded_file
    last_request.POST['photo'][:head].must_include 'content-length: 4'
  end

  it 'sends files as Tempfiles' do
    post '/', 'photo' => uploaded_file
    last_request.POST['photo'][:tempfile].class.must_equal Tempfile
  end

  it 'escapes spaces in filenames properly' do
    post '/', 'photo' => Rack::Test::UploadedFile.new(fixture_path('space case.txt'))
    last_request.POST['photo'][:filename].must_equal 'space case.txt'
  end
end

describe 'uploading two files' do
  include uploaded_files

  def second_test_file_path
    fixture_path('bar.txt')
  end

  def second_uploaded_file
    Rack::Test::UploadedFile.new(second_test_file_path)
  end

  it 'sends the multipart/form-data content type' do
    post '/', 'photos' => [uploaded_file, second_uploaded_file]
    last_request.env['CONTENT_TYPE'].must_include 'multipart/form-data;'
  end

  it 'sends files with the filename' do
    post '/', 'photos' => [uploaded_file, second_uploaded_file]
    last_request.POST['photos'].collect { |photo| photo[:filename] }.must_equal ['foo.txt', 'bar.txt']
  end

  it 'sends files with the text/plain MIME type by default' do
    post '/', 'photos' => [uploaded_file, second_uploaded_file]
    last_request.POST['photos'].collect { |photo| photo[:type] }.must_equal ['text/plain', 'text/plain']
  end

  it 'sends files with the right names' do
    post '/', 'photos' => [uploaded_file, second_uploaded_file]
    last_request.POST['photos'].all? { |photo| photo[:name].must_equal 'photos[]' }
  end

  it 'allows mixed content types' do
    image_file = Rack::Test::UploadedFile.new(first_test_file_path, 'image/jpeg')

    post '/', 'photos' => [uploaded_file, image_file]
    last_request.POST['photos'].collect { |photo| photo[:type] }.must_equal ['text/plain', 'image/jpeg']
  end

  it 'sends files with a content-length in the header' do
    post '/', 'photos' => [uploaded_file, second_uploaded_file]
    last_request.POST['photos'].all? { |photo| photo[:head].must_include 'content-length: 4' }
  end

  it 'sends both files as Tempfiles' do
    post '/', 'photos' => [uploaded_file, second_uploaded_file]
    last_request.POST['photos'].all? { |photo| photo[:tempfile].class.must_equal Tempfile }
  end
end
