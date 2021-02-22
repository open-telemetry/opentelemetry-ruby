# OpenTelemetry Redis Instrumentation

The OpenTelemetry Redis Ruby gem is a community maintained instrumentation for [Redis][redis-home]. This is an in-memory data store that is used as a database, cache, and message broker.

## How do I get started?

Install the gem using:

```
gem install opentelemetry-instrumentation-redis
```

Or, if you use [bundler][bundler-home], include `opentelemetry-instrumentation-redis` in your `Gemfile`.

## Usage

To install the instrumentation, call `use` with the name of the instrumentation.

```ruby
OpenTelemetry::SDK.configure do |c|
  c.use 'OpenTelemetry::Instrumentation::Redis'
end
```

Alternatively, you can also call `use_all` to install all the available instrumentation.

```ruby
OpenTelemetry::SDK.configure do |c|
  c.use_all
end
```

The Redis instrumentation allows the user to supply additional attributes via context propagation. This may be used to propagate attributes from instrumentation for things like Resque and Sidekiq, for example, to attach to the Redis client spans.

```ruby
require 'opentelemetry/instrumentation/redis'

redis = ::Redis.new
OpenTelemetry::Instrumentation::Redis.with_attributes('peer.service' => 'cache') do
  redis.set('K', 'x')
end
```

## Example

An example of usage can be seen in [`example/redis.rb`](https://github.com/open-telemetry/opentelemetry-ruby/blob/main/instrumentation/redis/example/redis.rb).

## How can I get involved?

The `opentelemetry-instrumentation-redis` gem source is [on github][repo-github], along with related gems including `opentelemetry-api` and `opentelemetry-sdk`.

The OpenTelemetry Ruby gems are maintained by the OpenTelemetry-Ruby special interest group (SIG). You can get involved by joining us in [GitHub Discussions][discussions-url] or attending our weekly meeting. See the [meeting calendar][community-meetings] for dates and times. For more information on this and other language SIGs, see the OpenTelemetry [community page][ruby-sig].

## License

Apache 2.0 license. See [LICENSE][license-github] for more information.

[redis-home]: https://redis.io
[bundler-home]: https://bundler.io
[repo-github]: https://github.com/open-telemetry/opentelemetry-ruby
[license-github]: https://github.com/open-telemetry/opentelemetry-ruby/blob/main/LICENSE
[ruby-sig]: https://github.com/open-telemetry/community#ruby-sig
[community-meetings]: https://github.com/open-telemetry/community#community-meetings
[discussions-url]: https://github.com/open-telemetry/opentelemetry-ruby/discussions
