require 'sidekiq-runner'

rails_env = Rake::Task.task_defined?(:environment) ? [:environment] : []

namespace :sidekiqrunner do
  desc 'Start sidekiq-runner instances'
  task start: rails_env do
    puts 'Starting sidekiq instances...'
    SidekiqRunner.start
  end

  desc 'Stop sidekiq-runner instances'
  task stop: rails_env do
    puts 'Gracefully shutting down sidekiq instances...'
    SidekiqRunner.stop
  end

  desc 'Restart sidekiq-runner instances'
  task restart: ['sidekiq:stop', 'sidekiq:start']
end
