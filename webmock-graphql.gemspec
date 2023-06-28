# frozen_string_literal: true

require_relative "lib/webmock/graphql/version"

Gem::Specification.new do |spec|
  spec.name = "webmock-graphql"
  spec.version = Webmock::Graphql::VERSION
  spec.authors = ["qsona"]
  spec.email = ["mori.jmk@gmail.com"]

  spec.summary = "Library for stubbing graphql request"
  spec.description = "Library for stubbing graphql request (from ruby to other services), wrapper of webmock"
  spec.homepage = "https://github.com/qsona/webmock-graphql"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.2.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "https://github.com/qsona/webmock-graphql/tree/master/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (File.expand_path(f) == __FILE__) || f.start_with?(*%w[bin/ test/ spec/ features/ .git .circleci appveyor])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "webmock"

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
end
