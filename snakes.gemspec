# frozen_string_literal: true

require_relative "lib/snakes/version"

Gem::Specification.new do |spec|
  spec.name = "snakes"
  spec.version = Snakes::VERSION
  spec.authors = ["Mark24"]
  spec.email = ["mark.zhangyoung@qq.com"]

  spec.summary = "Snakes game power by Ruby"
  spec.description = "Snakes game power by Ruby."
  spec.homepage = "https://github.com/Mark24Code/snakes"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 2.6.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/Mark24Code/snakes"
  spec.metadata["changelog_uri"] = "https://github.com/Mark24Code/snakes"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject do |f|
      (f == __FILE__) || f.match(%r{\A(?:(?:test|spec|features)/|\.(?:git|travis|circleci)|appveyor)})
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Uncomment to register a new dependency of your gem
  spec.add_runtime_dependency "curses", "~> 1.4.4"
  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
  # gemspec at: https://guides.rubygems.org/specification-reference
end
