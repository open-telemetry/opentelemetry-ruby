# OpenTelemetry RSpec Instrumentation

The RSpec instrumentation is a community-maintained instrumentation for the [RSpec][rspec-home] BDD testing framework.

## How do I get started?

Install the gem using:

```
gem install opentelemetry-instrumentation-rspec
```

Or, if you use [bundler][bundler-home], include `opentelemetry-instrumentation-rspec` in your `Gemfile`.

## Usage

To use the instrumentation, call `use` with the name of the instrumentation:

```ruby
OpenTelemetry::SDK.configure do |c|
  c.use 'OpenTelemetry::Instrumentation::Rspec'
end
```

Alternatively, you can add it directly to RSpec as a customer formatter:

```ruby
RSpec.configure do |config|
  config.formatter = OpenTelemetry::Instrumentation::RSpec::Formatter
end
```

### Using multiple tracer providers

By default the instrumentation will use the global tracer provider.

If you want the instrumentation to use something other than the global tracer provider you can configure the instrumentation with a custom tracer provider using the `OpenTelemetry::Instrumentation::RSpec::Formatter` constructor:

```ruby
exporter = OpenTelemetry::SDK::Trace::Export::InMemorySpanExporter.new
span_processor = OpenTelemetry::SDK::Trace::Export::SimpleSpanProcessor.new(exporter)
tracer_provider = OpenTelemetry::SDK::Trace::TracerProvider.new
tracer_provider.add_span_processor(span_processor)

RSpec.configure do |config|
  config.formatter = OpenTelemetry::Instrumentation::RSpec::Formatter.new(config.output_stream, tracer_provider)
end
```

If you need to test trace behaviour in your specs then you should be able to use a custom tracer provider and the instrumentation's output should not interfere with your specs.

### Sampling

To avoid spans from being dropped, which will mean you lose insight into your specs, you may want to set sampling to 'ALWAYS_ON'. The easiest way to do this is by setting the `OTEL_TRACES_SAMPLER` environment variable to `always_on`.

## Examples

Example usage can be seen in the `/example` directory [here](https://github.com/open-telemetry/opentelemetry-ruby/blob/main/instrumentation/rspec/example)

## How can I get involved?

The `opentelemetry-instrumentation-rspec` gem source is [on github][repo-github], along with related gems including `opentelemetry-api` and `opentelemetry-sdk`.

The OpenTelemetry Ruby gems are maintained by the OpenTelemetry-Ruby special interest group (SIG). You can get involved by joining us in [GitHub Discussions][discussions-url] or attending our weekly meeting. See the [meeting calendar][community-meetings] for dates and times. For more information on this and other language SIGs, see the OpenTelemetry [community page][ruby-sig].

## License

The `opentelemetry-instrumentation-rspec` gem is distributed under the Apache 2.0 license. See [LICENSE][license-github] for more information.

[bundler-home]: https://bundler.io
[repo-github]: https://github.com/open-telemetry/opentelemetry-ruby
[license-github]: https://github.com/open-telemetry/opentelemetry-ruby/blob/main/LICENSE
[ruby-sig]: https://github.com/open-telemetry/community#ruby-sig
[community-meetings]: https://github.com/open-telemetry/community#community-meetings
[discussions-url]: https://github.com/open-telemetry/opentelemetry-ruby/discussions
[rspec-home]: https://rspec.info
