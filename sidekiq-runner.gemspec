$:.unshift File.expand_path('../lib', __FILE__)
require 'sidekiq-runner/version'

Gem::Specification.new do |s|
  s.name          = 'sidekiq-runner'
  s.version       = SidekiqRunner::VERSION
  s.license       = 'MIT'
  s.summary       = 'Sidekiq configuration and rake tasks'
  s.description   = 'Provide an easy way to configure, start, and monitor all your Sidekiq processes'

  s.authors       = ['FlavourSys Technology GmbH']
  s.email         = 'technology@flavoursys.com'
  s.homepage      = 'https://github.com/FlavourSys/sidekiq-runner'

  s.require_paths = ['lib']
  s.files         = Dir.glob('lib/**/*.rb') + ['lib/sidekiq-runner/sidekiq.god'] + Dir.glob('script/*')

  s.add_runtime_dependency 'rake', '~> 0'
  s.add_dependency 'god', '~> 0.13'
  s.add_dependency 'sidekiq', '~> 6.0'
end
