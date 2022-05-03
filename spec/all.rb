Dir['spec/**/*_spec.rb'].each{|f| require_relative f.sub('spec/', '')}
