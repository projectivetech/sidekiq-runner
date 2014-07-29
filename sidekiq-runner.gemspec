$:.unshift File.expand_path('../lib', __FILE__)
require 'sidekiq-runner/version'

Gem::Specification.new do |s|
  s.name          = 'sidekiq-runner'
  s.version       = SidekiqRunner::VERSION
  s.license       = 'MIT'
  s.summary       = 'Sidekiq rake task collection'
  s.description   = 'A little collection of Sidekiq start/stop rake tasks and configuration framework'

  s.authors       = ['FlavourSys Technology GmbH']
  s.email         = 'technology@flavoursys.com'
  s.homepage      = 'https://github.com/FlavourSys/sidekiq-runner'

  s.require_paths = ['lib']
  s.files         = Dir.glob('lib/**/*.rb')

  s.add_dependency 'rake', '~> 10.3'
  s.add_dependency 'god', '~> 0.13'
end
