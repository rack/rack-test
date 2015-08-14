RSpec::Matchers.define :have_body do |expected|
  match do |response|
    expect(response.body).to eq(expected)
  end

  description do
    "have body #{expected.inspect}"
  end
end
