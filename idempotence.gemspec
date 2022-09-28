Gem::Specification.new do |spec|
  spec.name     = "idempotence"
  spec.version  = "1.0.0"
  spec.authors  = ["Alfonso Uceda"]
  spec.email    = ["alfonso@hubbado.com"]

  spec.summary  = "Idempotence library to handle reservation pattern in eventide toolkit"
  spec.homepage = "https://www.github.com/hubbado/idempotence"
  spec.license  = "MIT"
  spec.required_ruby_version = Gem::Requirement.new(">= 2.4.0")

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage

  spec.require_paths = ["lib"]
  spec.files = Dir.glob('{lib}/**/*')

  spec.add_runtime_dependency "evt-messaging-postgres"
  spec.add_runtime_dependency "evt-message_store"
  spec.add_runtime_dependency "evt-configure"
  spec.add_runtime_dependency "evt-dependency"
  spec.add_runtime_dependency "evt-try"
  spec.add_runtime_dependency "evt-log"

  spec.add_development_dependency "hubbado-style"
  spec.add_development_dependency "test_bench"
  spec.add_development_dependency "debug"
end