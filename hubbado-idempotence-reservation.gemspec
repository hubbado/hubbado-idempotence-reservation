Gem::Specification.new do |spec|
  spec.name     = "hubbado-idempotence-reservation"
  spec.version  = "2.2.3"
  spec.authors  = ["Hubbado"]
  spec.email    = ["devs@hubbado.com"]

  spec.summary  = "Idempotence library to handle reservation pattern in eventide toolkit"
  spec.homepage = "https://github.com/hubbado/hubbado-idempotence-reservation"
  spec.license  = "MIT"
  spec.required_ruby_version = Gem::Requirement.new(">= 3.0.0")

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["github_repo"] = spec.homepage

  spec.require_paths = ["lib"]
  spec.files = Dir.glob('{lib}/**/*')

  spec.add_runtime_dependency "evt-configure"
  spec.add_runtime_dependency "evt-dependency"
  spec.add_runtime_dependency "evt-log"
  spec.add_runtime_dependency "evt-message_store"
  spec.add_runtime_dependency "evt-messaging-postgres"
  spec.add_runtime_dependency "evt-try"

  spec.add_development_dependency "debug"
  spec.add_development_dependency "hubbado-style"
  spec.add_development_dependency "test_bench"
end
