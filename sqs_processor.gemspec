Gem::Specification.new do |spec|
  spec.name          = "sqs_processor"
  spec.version       = "0.1.0"
  spec.authors       = ["Your Name"]
  spec.email         = ["your.email@example.com"]
  spec.summary       = "A Ruby gem for processing messages from Amazon SQS queues"
  spec.description   = "A comprehensive Ruby gem for processing messages from Amazon SQS queues with configurable message handling, error recovery, and extensible processing logic."
  spec.homepage      = "https://github.com/yourusername/sqs_processor"
  spec.license       = "MIT"
  spec.required_ruby_version = ">= 2.6.0"

  spec.files         = Dir.glob("{bin,lib}/**/*") + %w[README.md LICENSE]
  spec.executables   = ["sqs_processor"]
  spec.require_paths = ["lib"]

  spec.add_dependency "aws-sdk-sqs", "~> 1.0"
  spec.add_dependency "json", "~> 2.0"
  spec.add_dependency "logger", "~> 1.0"
  spec.add_dependency "dotenv", "~> 2.0"

  spec.add_development_dependency "bundler", "~> 2.0"
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "rubocop", "~> 1.0"
end 