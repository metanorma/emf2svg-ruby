# frozen_string_literal: true

require_relative "lib/emf2svg/version"

Gem::Specification.new do |spec|
  spec.name          = "emf2svg"
  spec.version       = Emf2svg::VERSION
  spec.authors       = ["Ribose"]
  spec.email         = ["open.source@ribose.com"]

  spec.summary       = "Ruby interface to libemf2svg."
  # spec.description   = "TODO: Write a longer description or delete this line."
  spec.homepage      = "https://github.com/metanorma/emf2svg-ruby"
  spec.required_ruby_version = ">= 2.5.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/metanorma/emf2svg-ruby"
  spec.metadata["changelog_uri"] = "https://github.com/metanorma/emf2svg-ruby"

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject do |f|
      f.match(%r{\A(?:test|spec|features)/})
    end
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency "ffi", "~> 1.0"
  spec.add_runtime_dependency "mini_portile2", "~> 2.6"

  spec.add_development_dependency "rubocop", "1.5.2"
  spec.add_development_dependency "rubocop-performance"
  spec.add_development_dependency "rubocop-rails"

  spec.extensions = ["ext/extconf.rb"]
end
