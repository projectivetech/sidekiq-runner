module SidekiqCommandBuilder

  def self.build_start_command(sidekiq_config, skiq)
    cmd = []
    cmd << (skiq.bundle_env ? 'bundle exec sidekiq' : 'sidekiq')
    cmd << '-d' if sidekiq_config.daemonize
    cmd << "-c #{skiq.concurrency}"
    cmd << "-e #{Rails.env}" if defined?(Rails)
    cmd << '-v' if skiq.verbose
    cmd << "-L #{skiq.logfile}"
    cmd << "-P #{skiq.pidfile}"
    cmd << "-r #{skiq.requirefile}" if skiq.requirefile

    skiq.queues.each do |q, w|
      cmd << "-q #{q},#{w.to_s}"
    end

    cmd.join(' ')
  end

  def self.build_stop_command(skiq, timeout)
    cmd = []
    cmd << (skiq.bundle_env ? 'bundle exec sidekiqctl' : 'sidekiqctl')
    cmd << 'stop'
    cmd << skiq.pidfile
    cmd << timeout

    cmd.join(' ')
  end

end