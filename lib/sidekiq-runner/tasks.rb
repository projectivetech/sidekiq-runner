require 'sidekiq-runner'

rails_env = Rake::Task.task_defined?(:environment) ? [:environment] : []

namespace :sidekiq do
  desc 'Start sidekiq node'
  task start: rails_env do
    puts 'Starting sidekiq...'
    SidekiqRunner.start
  end

  desc 'Stop sidekiq node'
  task stop: rails_env do
    puts 'Gracefully shutting down sidekiq...'
    SidekiqRunner.stop
  end

  desc 'Restart sidekiq node'
  task restart: ['sidekiq:stop', 'sidekiq:start']
end
