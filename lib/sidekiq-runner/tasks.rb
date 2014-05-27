require 'sidekiq-runner'

namespace :sidekiq do
  desc 'Start sidekiq node'
  task :start => :environment do
    puts 'Starting sidekiq...'
    SidekiqRunner.start
  end

  desc 'Stop sidekiq node'
  task :stop => :environment do
    puts 'Gracefully shutting down sidekiq...'
    SidekiqRunner.stop
  end

  desc 'Restart sidekiq node'
  task :restart => ['sidekiq:stop', 'sidekiq:start']
end
