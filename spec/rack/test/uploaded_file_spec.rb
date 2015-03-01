require "spec_helper"

describe Rack::Test::UploadedFile do
  def test_file_path
    File.dirname(__FILE__) + "/../../fixtures/foo.txt"
  end

  it "responds to things that Tempfile responds to" do
    uploaded_file = Rack::Test::UploadedFile.new(test_file_path)

    uploaded_file.should respond_to(:close)
    uploaded_file.should respond_to(:close!)
    uploaded_file.should respond_to(:delete)
    uploaded_file.should respond_to(:length)
    uploaded_file.should respond_to(:open)
    uploaded_file.should respond_to(:path)
    uploaded_file.should respond_to(:size)
    uploaded_file.should respond_to(:unlink)
    uploaded_file.should respond_to(:read)
    uploaded_file.should respond_to(:original_filename)
    uploaded_file.should respond_to(:tempfile) # Allows calls to params[:file].tempfile
  end

  it 'closes the tempfile in initialize' do
    temp = Tempfile.new('test')
    tempfile = mock('Tempfile')
    tempfile.should_receive(:path).and_return(temp.path)
    tempfile.should_receive(:close)
    Tempfile.stub(:new).and_return(tempfile)

    Rack::Test::UploadedFile.new(test_file_path)
  end
end
