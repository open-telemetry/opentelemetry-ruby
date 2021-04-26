# OpenTelemetry Koala Instrumentation

The Koala instrumentation is a community-maintained instrumentation for the [Koala][koala-home] Facebook API library.

## How do I get started?

Install the gem using:

```
gem install opentelemetry-instrumentation-koala
```

Or, if you use [bundler][bundler-home], include `opentelemetry-instrumentation-koala` in your `Gemfile`.

## Usage

To use the instrumentation, call `use` with the name of the instrumentation:

```ruby
OpenTelemetry::SDK.configure do |c|
  c.use 'OpenTelemetry::Instrumentation::Net::HTTP'
  c.use 'OpenTelemetry::Instrumentation::Koala'
end
```

Alternatively, you can also call `use_all` to install all the available instrumentation.

```ruby
OpenTelemetry::SDK.configure do |c|
  c.use_all
end
```

## Examples

Example usage can be seen in the `./example/trace_demonstration.rb` file [here](https://github.com/open-telemetry/opentelemetry-ruby/blob/master/instrumentation/koala/example/trace_demonstration.rb)

## How can I get involved?

The `opentelemetry-instrumentation-koala` gem source is [on github][repo-github], along with related gems including `opentelemetry-api` and `opentelemetry-sdk`.

The OpenTelemetry Ruby gems are maintained by the OpenTelemetry-Ruby special interest group (SIG). You can get involved by joining us in [GitHub Discussions][discussions-url] or attending our weekly meeting. See the [meeting calendar][community-meetings] for dates and times. For more information on this and other language SIGs, see the OpenTelemetry [community page][ruby-sig].

## License

The `opentelemetry-instrumentation-koala` gem is distributed under the Apache 2.0 license. See [LICENSE][license-github] for more information.

[koala-home]: https://github.com/arsduo/koala
[bundler-home]: https://bundler.io
[repo-github]: https://github.com/open-telemetry/opentelemetry-ruby
[license-github]: https://github.com/open-telemetry/opentelemetry-ruby/blob/master/LICENSE
[ruby-sig]: https://github.com/open-telemetry/community#ruby-sig
[community-meetings]: https://github.com/open-telemetry/community#community-meetings
[discussions-url]: https://github.com/open-telemetry/opentelemetry-ruby/discussions
