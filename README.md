# SidekiqRunner
This gem allows to run and monitor multiple instances of [Sidekiq](https://github.com/mperham/sidekiq). Configuration of the individual instances can either be done in code or in a configuration file.

SidekiqRunner uses [God](http://godrb.com) for monitoring Sidekiq instances. By default, God keeps all instances running and starts them whenever they fail.

## Use case

As of today, Sidekiq does not provide any means of starting/stopping the process automatically given a set of configuration options. Often, custom Rake tasks are written that encapsulate the Sidekiq command line parameters. Configuration is either stored directly in such Rake tasks or scripts or is placed in a YAML-formatted configuration file, in Rails environments often called `config/sidekiq.yml`.

For one of our products, we wanted to be able to both specify configuration options in (versioned) code and in a configuration file that could be customized per installation site. The user should be able to adapt settings such as the path to Sidekiq's logfile, whereas basic options such as the name and weight of the queues to be processed should be set within the code and should not be modifiable by the user.

Additionally, we wanted an easy way to monitor and automatically restart failed Sidekiq instances which is why [God](http://godrb.com) was introduced as a lightweight supervisor.

## Installation

Add SidekiqRunner to your Gemfile:

```ruby
# Gemfile

gem 'sidekiq-runner'
```

### (Non-Rails) Ruby application

Add configuration code to some arbitrary file (e.g., `lib/sidekiq.rb`):

```ruby
# lib/sidekiq.rb

require 'sidekiq-runner'

SidekiqRunner.configure do |config|
  # See below.
end
```

Add Rake tasks to your application, making sure the configuration is loaded, too:

```ruby
# Rakefile

require 'sidekiq-runner/tasks'
require_relative './lib/sidekiq.rb' # Or any other way...
```

### Rails

The configuration code can be put into an initializer:

```ruby
# config/initializer/sidekiq.rb

require 'sidekiq-runner'

SidekiqRunner.configure do |config|
  # See below.
end
```

SidekiqRunner will automatically load the Rails environment as a prerequisite of its own Rake tasks, so this time there is no need to require the configuration on its own:

```ruby
# Rakefile

require 'sidekiq-runner/tasks'
```

## Configuration

Example of a factory configuration of 2 Sidekiq processes:


```ruby
SidekiqRunner.configure do |config|
  config.config_file = '/some/other/path/sidekiq.yml'

  config.add_instance('bigbang') do |instance|
    instance.verbose = true

    # Add a queue 'sheldon' with weight 2.
    instance.add_queue 'sheldon', 2
    instance.add_queue 'penny', 4

    # Default weight is 1.
    instance.add_queue 'raj'
  end 

  config.add_instance('southpark') do |instance|
    instance.concurrency = 30
    instance.add_queue 'cartman'
    instance.pidfile = '/path/to/the/pid-file.pid'
    instance.logfile = '/path/to/the/log-file.log'
  end
end

SidekiqRunner.configure_god do |god_config|
  god_config.interval = 30
  god_config.maximum_memory_usage = 4000 # 4 GB.
end
```

### Global SidekiqRunner options

Until now, there is only one global SidekiqRunner option which has to be set outside of any instance blocks:

<table>
  <thead>
    <tr>
      <th>Option</th>
      <th>Default</th>
      <th>?</th>
    <tr>
  </thead>
  <tbody>
    <tr>
      <td><code>config_file</code></td>
      <td><code>$PWD/config/sidekiq.yml</code></td>
      <td>Configuration file for user customized settings</td>
    <tr>
  </tbody>
</table>

### Sidekiq instance options

Options for Sidekiq instances may either be set inside an instance block, in which case they apply only to the current Sidekiq instance, or outside of it (calling them on `config`), in which case they apply to all previously defined Sidekiq instances (see below). Some of them are overwritable by the user-provided configuration file, while others are not. Queues (set with `add_queue` method) are never overwritable.

<table>
  <thead>
    <tr>
      <th>Option</th>
      <th>Default</th>
      <th>?</th>
      <th>Overwritable?</th>
    <tr>
  </thead>
  <tbody>
    <tr>
      <td><code>verbose</code></td>
      <td><code>false</code></td>
      <td>Sets Sidekiq log level to <code>DEBUG</code></td>
      <td>&#10003;</td>
    <tr>
    <tr>
      <td><code>concurrency</code></td>
      <td><code>4</code></td>
      <td>Number of worker threads</td>
      <td>&#10003;</td>
    <tr>
    <tr>
      <td><code>bundle_env</code></td>
      <td><code>true</code></td>
      <td>Loads Sidekiq in new bundler environment</td>
      <td></td>
    </tr>
    <tr>
      <td><code>chdir</code></td>
      <td><code>nil</code></td>
      <td>Loads Sidekiq in a different working directory</td>
      <td></td>
    </tr>
    <tr>
      <td><code>requirefile</code></td>
      <td><code>nil</code></td>
      <td>Tells Sidekiq to load this file as main entry point</td>
      <td></td>
    </tr>
    <tr>
      <td><code>pidfile</code></td>
      <td><code>$PWD/tmp/pids/#{name}.pid</code></td>
      <td>PID file of the Sidekiq instance</td>
      <td>&#10003;</td>
    </tr>
    <tr>
      <td><code>logfile</code></td>
      <td><code>$PWD/log/#{name}.log</code></td>
      <td>Log file of the Sidekiq instance</td>
      <td>&#10003;</td>
    </tr>
    <tr>
      <td><code>tag</code></td>
      <td><code>#{name}</code></td>
      <td>Sets the Sidekiq process tag</td>
      <td>&#10003;</td>
    </tr>
  </tbody>
</table>

### God options

God configuration options, also some of them overwritable by the config file. For more information, please see the God [documentation](http://godrb.com/).

<table>
  <thead>
    <tr>
      <th>Option</th>
      <th>Default</th>
      <th>?</th>
      <th>Overwritable</th>
    <tr>
  </thead>
  <tbody>
    <tr>
      <td><code>config_file</code></td>
      <td><code>$PWD/config/god.yml</code></td>
      <td>Configuration file for user customized God settings</td>
      <td></td>
    <tr>
    <tr>
      <td><code>daemonize</code></td>
      <td><code>true</code></td>
      <td>Tells God to daemonize after start</td>
      <td></td>
    <tr>
    <tr>
      <td><code>port</code></td>
      <td><code>17165</code></td>
      <td>Communication port (God creates <code>/tmp/god.#{port}.sock</code>, no TCP)</td>
      <td></td>
    </tr>
    <tr>
      <td><code>syslog</code></td>
      <td><code>true</code></td>
      <td>Tells God to use syslog</td>
      <td></td>
    </tr>
    <tr>
      <td><code>events</code></td>
      <td><code>true</code></td>
      <td>Tells God the use the events framework</td>
      <td></td>
    </tr>
    <tr>
      <td><code>process_name</code></td>
      <td><code>sidekiq</code></td>
      <td>Name of the God process (SidekiqRunner will show up as <code>SidekiqRunner/God (#{name})</code> in process listings)</td>
      <td>&#10003;</td>
    </tr>
    <tr>
      <td><code>interval</code></td>
      <td><code>30</code></td>
      <td>Monitor interval</td>
      <td>&#10003;</td>
    </tr>
    <tr>
      <td><code>stop_timeout</code></td>
      <td><code>30</code></td>
      <td>Stop timeout</td>
      <td>&#10003;</td>
    </tr>
    <tr>
      <td><code>log_file</code></td>
      <td><code>$PWD/log/god.log</code></td>
      <td>Log file of the God process</td>
      <td>&#10003;</td>
    </tr>
    <tr>
      <td><code>maximum_memory_usage</code></td>
      <td>(unset)</td>
      <td>Restart instance when it hits memory limit (in MB)</td>
      <td>&#10003;</td>
    </tr>
  </tbody>
</table>

### Using instance options on all instances

You may apply instance configuration options to all instances by specifying them after the instances have been defined.

```ruby
SidekiqRunner.configure do |config|
  config.add_instance('1') do ... end

  config.verbose = true # Applies to '1'

  config.add_instance('2') do ... end

  config.concurrency = 40 # Applies to '1' and '2'
end
```

Please note that when no instance has been defined, a default instance called `sidekiq_default` will be created. It is therefore possible to configure SidekiqRunner without defining any instances:

```ruby
SidekiqRunner.configure do |config|
  config.add_queue 'local'
end
```

### Callbacks

Optionally you can add some callbacks which are executed after various events:

```ruby
SidekiqRunner.configure do |config|
  config.on_start_success do
    puts 'Yaaay, processes were started successfully.'
  end
  config.on_start_error do ... end
  config.on_stop_success do ... end
  config.on_stop_error do ... end
end
```



## Start & Stop

Start SidekiqRunner from the root of your application to start all defined Sidekiq instances:

```bash
$ [RAILS_ENV=production] bundle exec rake sidekiqrunner:start
```

```bash
$ [RAILS_ENV=production] bundle exec rake sidekiqrunner:restart
```

```bash
$ [RAILS_ENV=production] bundle exec rake sidekiqrunner:stop
```

## License
The SidekiqRunner gem is licensed under the MIT license. Please see the [LICENSE](https://github.com/FlavourSys/sidekiq-runner/master/LICENSE) file for more details.
