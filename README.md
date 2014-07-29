# SidekiqRunner
This gem allows to run and monitor multiple instances of [Sidekiq](https://github.com/mperham/sidekiq). Configuration of the individual instances can either be done in code or in a configuration file.

SidekiqRunner uses [God](http://godrb.com) for monitoring Sidekiq instances. By default, God keeps all instances running and starts them whenever they fail.

## Use case

As of today, Sidekiq does not provide any means of starting/stopping the process automatically given a set of configuration options. Often, custom Rake tasks are written that encapsulate the Sidekiq command line parameters. Configuration is either stored directly in such Rake tasks or scripts or is placed in a YAML-formatted configuration file, in Rails environments often called `config/sidekiq.yml`.

For one of our products, we wanted to be able to both specify configuration options in (versioned) code and in a configuration file that could be customized per installation site. The user should be able to adapt settings such as the path to Sidekiq's logfile, whereas basic options such as the name and weight of the queues to be processed should be set within the code and should not be modifiable by the user.

Additionally, we wanted an easy way to monitor and automatically restart failed Sidekiq instances which is why [God](http://godrb.com) was introduced as a lightweight supervisor.

## Installation
The easiest way of installing SidekiqRunner is through RubyGems:
```
$ [sudo] gem install sidekiq-runner
```

## Usage
1. Add SidekiqRunner to you Gemfile:
  ```bash
  gem 'sidekiq-runner'
  ```

2. Configure sidekiq instances and their queues:
  ```ruby
  SidekiqRunner.configure do |config|
    # common SidekiqRunner attributes
    config.config_file = '/path/to/the/sidekiq-runner-config.yml'
    config.daemonize = true

    # attributes specific to particular Sidekiq instances
    config.add_instance('bigbang') do |instance|
      instance.concurrency = 20
      instance.verbose = true
      instance.add_queue('sheldon', 2)
      instance.add_queue('penny', 4)
      instance.add_queue('raj')
    end 

    config.add_instance('southpark') do |instance|
      instance.concurrency = 30
      instance.add_queue('cartman')
      instance.pidfile = '/path/to/the/pid-file.pid'
      instance.logfile = '/path/to/the/log-file.log'
    end
  end
  ```

  * `config_file` - optional path to a yml file with SidekiqRunner configuration, defaults to `config/sidekiq.yml` below the current directory
  * `daemonize` - indicates whether Sidekiq instances should be daemonized 
  * `add_queue(queue_name, priority = 1)` - more details at [Sidekiq queues doc](https://github.com/mperham/sidekiq/wiki/Advanced-Options#queues)

3. Optionally you can add some callbacks:
  ```ruby
  SidekiqRunner.configure do |config|
    config.on_start_success do
      puts 'Yaaay, processes were started successfully.'
    end
    config.on_start_error do
      puts 'Booo, there was a problem with starting processes.'
    end
    config.on_stop_success do
      puts 'Yaaay, processes were stopped successfully.'
    end
    config.on_stop_error do
      puts 'Booo, there was a problem with stopping processes.'
    end
  end
  ```

4. Start SidekiqRunner from the root of your Rails application to start all defined Sidekiq instances:
  ```bash
  $ bundle exec rake sidekiqrunner:start
  ```

## Advanced configuration
You can also configure some of the God options:
```ruby
SidekiqRunner.configure_god do |god_config|
  god_config.config_file = '/path/to/the/god-config.yml'
  god_config.daemonize = true
  god_config.interval = 30
end
```

1. SidekiqRunner options:
  * `:config_file, :daemonize`
  * NONE overwritable by the yml file
2. Sidekiq instance options:
  * `:bundle_env, :chdir, :requirefile, :concurrency, :verbose, :pidfile, :logfile`
  * ALL overwritable by the yml file
3. God options:
  * `:config_file, :daemonize, :port, :syslog, :events, :options`
  * overwritable by the yml file: `:process_name, :interval, :stop_timeout, :log_file`

## License
The SidekiqRunner gem is licensed under the MIT license. Please see the [LICENSE](https://github.com/FlavourSys/sidekiq-runner/master/LICENSE) file for more details.
