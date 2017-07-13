module GemHelpers
  def read_gemspec
    @read_gemspec ||= eval(File.read('rack-test.gemspec'))
  end

  def sh(command)
    puts command
    system command
  end
end

class Default < Thor
  include GemHelpers

  desc 'build', 'Build a rack-test gem'
  def build
    sh 'gem build rack-test.gemspec'
    FileUtils.mkdir_p 'pkg'
    FileUtils.mv read_gemspec.file_name, 'pkg'
  end

  desc 'install', 'Install the latest built gem'
  def install
    sh "gem install --local pkg/#{read_gemspec.file_name}"
  end

  desc 'release', 'Release the current branch to GitHub and RubyGems.org'
  def release
    build
    Release.new.tag
    Release.new.gem
  end
end

class Release < Thor
  include GemHelpers

  desc 'tag', 'Tag the gem on the origin server'
  def tag
    release_tag = "v#{read_gemspec.version}"
    sh "git tag -a #{release_tag} -m 'Tagging #{release_tag}'"
    sh "git push origin #{release_tag}"
  end

  desc 'gem', 'Push the gem to RubyGems.org'
  def gem
    sh "gem push pkg/#{read_gemspec.file_name}"
  end
end
