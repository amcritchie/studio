require_relative "lib/studio/version"

Gem::Specification.new do |spec|
  spec.name        = "studio"
  spec.version     = Studio::VERSION
  spec.authors     = ["Alex McRitchie"]
  spec.summary     = "Shared engine for McRitchie Studio apps"

  spec.files = Dir["lib/**/*", "app/**/*", "config/**/*", "tailwind/**/*", "Gemfile", "studio.gemspec"]
  spec.require_paths = ["lib"]

  spec.add_dependency "rails", ">= 7.0"
  spec.add_dependency "tailwindcss-rails", "~> 2.7"
end
