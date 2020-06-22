require_relative 'lib/kiwi'

Gem::Specification.new do |spec|
  spec.name          = "kiwi-schema"
  spec.version       = Kiwi::VERSION
  spec.authors       = ["Jan Habermann"]
  spec.email         = ["jan@habermann.io"]
  spec.summary       = %q{Kiwi encoding/decoding in ruby}
  spec.description   = %q{Kiwi encoding/decoding in ruby}
  spec.homepage      = "https://www.github/com/haberbyte/kiwi-schema"
  spec.required_ruby_version = Gem::Requirement.new(">= 2.3.0")
  spec.metadata["homepage_uri"] = spec.homepage
  spec.files = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.require_paths = ["lib"]
end
