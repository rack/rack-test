Dir.glob('spec/**/*_spec.rb') {|f| require_relative f.sub('spec/', '')}
