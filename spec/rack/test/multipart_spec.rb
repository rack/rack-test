# encoding: UTF-8

require 'spec_helper'

describe Rack::Test::Session do
  def fixture_path(name)
    return File.join(File.dirname(__FILE__), '..', '..', 'fixtures', name)
  end

  def test_file_path
    return fixture_path('foo.txt')
  end

  def second_test_file_path
    return fixture_path('bar.txt')
  end

  def uploaded_file
    Rack::Test::UploadedFile.new(test_file_path)
  end

  def second_uploaded_file
    Rack::Test::UploadedFile.new(second_test_file_path)
  end

  context 'uploading a file' do
    it 'sends the multipart/form-data content type if no content type is specified' do
      post '/', 'photo' => uploaded_file
      expect(last_request.env['CONTENT_TYPE']).to include('multipart/form-data;')
    end

    it 'sends multipart/related content type if it is explicitly specified' do
      post '/', { 'photo' => uploaded_file }, 'CONTENT_TYPE' => 'multipart/related'
      expect(last_request.env['CONTENT_TYPE']).to include('multipart/related;')
    end

    it 'sends regular params' do
      post '/', 'photo' => uploaded_file, 'foo' => 'bar'
      expect(last_request.POST['foo']).to eq('bar')
    end

    it 'sends nested params' do
      post '/', 'photo' => uploaded_file, 'foo' => { 'bar' => 'baz' }
      expect(last_request.POST['foo']['bar']).to eq('baz')
    end

    it 'sends multiple nested params' do
      post '/', 'photo' => uploaded_file, 'foo' => { 'bar' => { 'baz' => 'bop' } }
      expect(last_request.POST['foo']['bar']['baz']).to eq('bop')
    end

    it 'sends params with arrays' do
      post '/', 'photo' => uploaded_file, 'foo' => %w[1 2]
      expect(last_request.POST['foo']).to eq(%w[1 2])
    end

    it 'sends params with encoding sensitive values' do
      post '/', 'photo' => uploaded_file, 'foo' => 'bar? baz'
      expect(last_request.POST['foo']).to eq('bar? baz')
    end

    it 'sends params encoded as ISO-8859-1' do
      post '/', 'photo' => uploaded_file, 'foo' => 'bar', 'utf8' => '☃'
      expect(last_request.POST['foo']).to eq('bar')

      expected_value = if Rack::Test.encoding_aware_strings?
        '☃'
      else
        "\xE2\x98\x83"
      end

      expect(last_request.POST['utf8']).to eq(expected_value)
    end

    it 'sends params with parens in names' do
      post '/', 'photo' => uploaded_file, 'foo(1i)' => 'bar'
      expect(last_request.POST['foo(1i)']).to eq('bar')
    end

    it 'sends params with encoding sensitive names' do
      post '/', 'photo' => uploaded_file, 'foo bar' => 'baz'
      expect(last_request.POST['foo bar']).to eq('baz')
    end

    it 'sends files with the filename' do
      post '/', 'photo' => uploaded_file
      expect(last_request.POST['photo'][:filename]).to eq('foo.txt')
    end

    it 'sends files with the text/plain MIME type by default' do
      post '/', 'photo' => uploaded_file
      expect(last_request.POST['photo'][:type]).to eq('text/plain')
    end

    it 'sends files with the right name' do
      post '/', 'photo' => uploaded_file
      expect(last_request.POST['photo'][:name]).to eq('photo')
    end

    it 'allows overriding the content type' do
      post '/', 'photo' => Rack::Test::UploadedFile.new(test_file_path, 'image/jpeg')
      expect(last_request.POST['photo'][:type]).to eq('image/jpeg')
    end

    it 'sends files with a Content-Length in the header' do
      post '/', 'photo' => uploaded_file
      expect(last_request.POST['photo'][:head]).to include('Content-Length: 4')
    end

    it 'sends files as Tempfiles' do
      post '/', 'photo' => uploaded_file
      expect(last_request.POST['photo'][:tempfile]).to be_a(::Tempfile)
    end

    it 'escapes spaces in filenames properly' do
      post '/', 'photo' => Rack::Test::UploadedFile.new(fixture_path('space case.txt'))
      expect(last_request.POST['photo'][:filename]).to eq('space case.txt')
    end
  end

  context 'uploading two files' do
    it 'sends the multipart/form-data content type' do
      post '/', 'photos' => [uploaded_file, second_uploaded_file]
      expect(last_request.env['CONTENT_TYPE']).to include('multipart/form-data;')
    end

    it 'sends files with the filename' do
      post '/', 'photos' => [uploaded_file, second_uploaded_file]
      expect(last_request.POST['photos'].collect { |photo| photo[:filename] }).to eq(['foo.txt', 'bar.txt'])
    end

    it 'sends files with the text/plain MIME type by default' do
      post '/', 'photos' => [uploaded_file, second_uploaded_file]
      expect(last_request.POST['photos'].collect { |photo| photo[:type] }).to eq(['text/plain', 'text/plain'])
    end

    it 'sends files with the right names' do
      post '/', 'photos' => [uploaded_file, second_uploaded_file]
      last_request.POST['photos'].all? { |photo| expect(photo[:name]).to eq('photos[]') }
    end

    it 'allows mixed content types' do
      image_file = Rack::Test::UploadedFile.new(test_file_path, 'image/jpeg')

      post '/', 'photos' => [uploaded_file, image_file]
      expect(last_request.POST['photos'].collect { |photo| photo[:type] }).to eq(['text/plain', 'image/jpeg'])
    end

    it 'sends files with a Content-Length in the header' do
      post '/', 'photos' => [uploaded_file, second_uploaded_file]
      last_request.POST['photos'].all? { |photo| expect(photo[:head]).to include('Content-Length: 4') }
    end

    it 'sends both files as Tempfiles' do
      post '/', 'photos' => [uploaded_file, second_uploaded_file]
      last_request.POST['photos'].all? { |photo| expect(photo[:tempfile]).to be_a(::Tempfile) }
    end
  end
end
