# OpenTelemetry Mongo Instrumentation

The OpenTelemetry Mongo Ruby gem is a community maintained instrumentation for [Mongo][mongo-home].

## How do I get started?

Install the gem using:

```
gem install opentelemetry-instrumentation-mongo
```

Or, if you use [bundler][bundler-home], include `opentelemetry-instrumentation-mongo` in your `Gemfile`.

## Usage

To install the instrumentation, call `use` with the name of the instrumentation.

```ruby
OpenTelemetry::SDK.configure do |c|
  c.use 'OpenTelemetry::Instrumentation::Mongo'
end
```

Alternatively, you can also call `use_all` to install all the available instrumentation.

```ruby
OpenTelemetry::SDK.configure do |c|
  c.use_all
end
```

## Example

To run the example:

1. Start MongoDB using docker-compose
	* `docker-compose up mongo`
2. In a separate terminal window, `cd` to the examples directory and install gems
	* `cd example`
	* `bundle install`
3. Run the sample client script
	* `ruby mongo.rb`

This will run a few MongoDB commands, printing OpenTelemetry traces to the console as it goes.

## How can I get involved?

The `opentelemetry-instrumentation-mongo` gem source is [on github][repo-github], along with related gems including `opentelemetry-api` and `opentelemetry-sdk`.

The OpenTelemetry Ruby gems are maintained by the OpenTelemetry-Ruby special interest group (SIG). You can get involved by joining us in [GitHub Discussions][discussions-url] or attending our weekly meeting. See the [meeting calendar][community-meetings] for dates and times. For more information on this and other language SIGs, see the OpenTelemetry [community page][ruby-sig].

## License

Apache 2.0 license. See [LICENSE][license-github] for more information.

[mongo-home]: https://github.com/mongodb/mongo-ruby-driver
[bundler-home]: https://bundler.io
[repo-github]: https://github.com/open-telemetry/opentelemetry-ruby
[license-github]: https://github.com/open-telemetry/opentelemetry-ruby/blob/main/LICENSE
[ruby-sig]: https://github.com/open-telemetry/community#ruby-sig
[community-meetings]: https://github.com/open-telemetry/community#community-meetings
[discussions-url]: https://github.com/open-telemetry/opentelemetry-ruby/discussions

