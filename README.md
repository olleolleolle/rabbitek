# Rabbitek

High performance, easy to use background job processing library for Ruby using RabbitMQ queues.

* Consumers (servers) are configurable via yaml files.
* Retries
* Delayed jobs
* Jobs priority (through RabbitMQ Priority Queues)
* Scalable and failure-safe
* Client & Server hooks
* OpenTracing (http://opentracing.io/) instrumentation
* NewRelic instrumentation for sending errors

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'rabbitek'
```

And then execute:

    $ bundle

## Usage

First, you need configuration file:

```yaml
# config/rabbitek.yml
consumers:
  - FirstConsumer
  - SecondConsumer  
threads: 25
parameters:
  queue: myqueue
  basic_qos: 20
  queue_attributes:
    arguments:
      x-max-priority: 10
```

Create consumer and include `Rabbitek::Consumer`, add `rabbit_options` with path to config file
and create `perform` method same way as on example:

```
  class ExampleConsumer
    include Rabbitek::Consumer

    rabbit_options config_file: 'config/rabbitek.yml'

    def perform(message)
      puts "Payload: #{message.payload}"
      puts "Delivery Info: "#{message.delivery_info}"
      puts "Properties: "#{message.properties}"
      
      # Mesage will be automatically acked unless exception is raised 
    end
  end
```

Lastly, run server:

```
bundle exec rabbitek
```

You can schedule jobs e.g.: `ExampleCustomer.perform_async(some: :payload)`

### Batching

```
  class ExampleConsumer
    include Rabbitek::Consumer

    rabbit_options config_file: 'config/rabbitek.yml', batch: 1000

    # When batch is defined, the perform method will have batch of up to N messages yielded.
    def perform(messages)
    end
  end
```

## Roadmap

* more tests!
* dead queue
* CRON jobs
* extended docs and how to
* prometheus metrics


## Development

After checking out the repo, run `bin/setup` to install dependencies. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/Boostcom/rabbitek.

## License

Please see [LICENSE.txt](LICENSE.txt)

## Author

![Boostcom](boostcom-logo.png)

**[Boostcom](https://boostcom.com/)** - we provide the most powerful management- and loyalty platform built for the needs of shopping centres.

