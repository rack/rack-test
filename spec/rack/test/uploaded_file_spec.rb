require 'spec_helper'

describe Rack::Test::UploadedFile do
  def test_file_path
    File.dirname(__FILE__) + '/../../fixtures/foo.txt'
  end

  it 'returns an instance of `Rack::Test::UploadedFile`' do
    uploaded_file = Rack::Test::UploadedFile.new(test_file_path)

    expect(uploaded_file).to be_a(Rack::Test::UploadedFile)
  end

  it 'responds to things that Tempfile responds to' do
    uploaded_file = Rack::Test::UploadedFile.new(test_file_path)

    Tempfile.public_instance_methods(false).each do |method|
      expect(uploaded_file).to respond_to(method)
    end
  end

  it "creates Tempfiles with original file's extension" do
    uploaded_file = Rack::Test::UploadedFile.new(test_file_path)

    expect(File.extname(uploaded_file.path)).to eq('.txt')
  end

  context 'it should call its destructor' do
    it 'calls the destructor' do
      expect(Rack::Test::UploadedFile).to receive(:actually_finalize).at_least(:once)

      if RUBY_PLATFORM == 'java'
        require 'java'
        java_import 'java.lang.System'

        50.times do |_i|
          Rack::Test::UploadedFile.new(test_file_path)
          System.gc
        end
      else
        Rack::Test::UploadedFile.new(test_file_path)
        GC.start
      end
    end
  end
end
