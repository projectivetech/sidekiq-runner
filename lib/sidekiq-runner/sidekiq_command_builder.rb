module SidekiqCommandBuilder

  def self.build_start_command(config)
    cmd = []
    cmd << (config.bundle_env ? 'bundle exec sidekiq' : 'sidekiq')
    cmd << '-d' if config.daemonize
    cmd << "-c #{config.concurrency}"
    cmd << "-e #{Rails.env}" if defined?(Rails)
    cmd << '-v' if config.verbose
    cmd << "-L #{config.logfile}"
    cmd << "-P #{config.pidfile}"
    cmd << "-r #{config.requirefile}" if config.requirefile

    config.queues.each do |q, w|
      cmd << "-q #{q},#{w}"
    end

    cmd.join(' ')
  end

  def self.build_stop_command(config, timeout)
    cmd = []
    cmd << (config.bundle_env ? 'bundle exec sidekiqctl' : 'sidekiqctl')
    cmd << 'stop'
    cmd << config.pidfile
    cmd << timeout

    cmd.join(' ')
  end

end