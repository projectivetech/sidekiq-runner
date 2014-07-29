require 'sidekiq-runner'

rails_env = Rake::Task.task_defined?(:environment) ? [:environment] : []

namespace :sidekiqrunner do
  desc 'Start Sidekiq instances'
  task start: rails_env do
    puts 'Starting sidekiq instances...'
    SidekiqRunner.start
  end

  desc 'Stop Sidekiq instances'
  task stop: rails_env do
    puts 'Gracefully shutting down sidekiq instances...'
    SidekiqRunner.stop
  end

  desc 'Restart Sidekiq instances'
  task restart: ['sidekiqrunner:stop', 'sidekiqrunner:start']
end
