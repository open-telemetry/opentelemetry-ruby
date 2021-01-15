# opentelemetry-exporter-otlp

The `opentelemetry-exporter-otlp` gem provides an [OTLP](https://github.com/open-telemetry/opentelemetry-proto) exporter for OpenTelemetry for Ruby. Using `opentelemetry-exporter-otlp`, an application can configure OpenTelemetry to export collected tracing data to [the OpenTelemetry Collector][opentelemetry-collector-home].

## What is OpenTelemetry?

[OpenTelemetry][opentelemetry-home] is an open source observability framework, providing a general-purpose API, SDK, and related tools required for the instrumentation of cloud-native software, frameworks, and libraries.

OpenTelemetry provides a single set of APIs, libraries, agents, and collector services to capture distributed traces and metrics from your application. You can analyze them using Prometheus, Jaeger, and other observability tools.

## How does this gem fit in?

The `opentelemetry-exporter-otlp` gem is a plugin that provides OTLP export. To export to the OpenTelemetry Collector, an application can include this gem along with `opentelemetry-sdk`, and configure the `SDK` to use the provided OTLP exporter as a span processor.

Generally, *libraries* that produce telemetry data should avoid depending directly on specific exporter, deferring that choice to the application developer.

### Supported protocol version

This gem supports the [v0.4.0 release](https://github.com/open-telemetry/opentelemetry-proto/releases/tag/v0.4.0) of OTLP.

## How do I get started?

Install the gem using:

```
gem install opentelemetry-sdk
gem install opentelemetry-exporter-otlp
```

Or, if you use [bundler][bundler-home], include `opentelemetry-sdk` in your `Gemfile`.

Then, configure the SDK to use the OTLP exporter as a span processor, and use the OpenTelemetry interfaces to produces traces and other information. Following is a basic example.

```ruby
require 'opentelemetry/sdk'
require 'opentelemetry/exporter/otlp'

# Configure the sdk with custom export
OpenTelemetry::SDK.configure do |c|
  c.add_span_processor(
    OpenTelemetry::SDK::Trace::Export::BatchSpanProcessor.new(
      exporter: OpenTelemetry::Exporter::OTLP::Exporter.new(
        endpoint: 'http://localhost:55680'
      )
    )
  )
end

# To start a trace you need to get a Tracer from the TracerProvider
tracer = OpenTelemetry.tracer_provider.tracer('my_app_or_gem', '0.1.0')

# create a span
tracer.in_span('foo') do |span|
  # set an attribute
  span.set_attribute('platform', 'osx')
  # add an event
  span.add_event('event in bar')
  # create bar as child of foo
  tracer.in_span('bar') do |child_span|
    # inspect the span
    pp child_span
  end
end
```

For additional examples, see the [examples on github][examples-github].

## How can I get involved?

The `opentelemetry-exporter-otlp` gem source is [on github][repo-github], along with related gems including `opentelemetry-sdk`.

The OpenTelemetry Ruby gems are maintained by the OpenTelemetry-Ruby special interest group (SIG). You can get involved by joining us on our [gitter channel][ruby-gitter] or attending our weekly meeting. See the [meeting calendar][community-meetings] for dates and times. For more information on this and other language SIGs, see the OpenTelemetry [community page][ruby-sig].

## License

The `opentelemetry-exporter-otlp` gem is distributed under the Apache 2.0 license. See [LICENSE][license-github] for more information.


[opentelemetry-collector-home]: https://opentelemetry.io/docs/collector/about/
[opentelemetry-home]: https://opentelemetry.io
[bundler-home]: https://bundler.io
[repo-github]: https://github.com/open-telemetry/opentelemetry-ruby
[license-github]: https://github.com/open-telemetry/opentelemetry-ruby/blob/master/LICENSE
[examples-github]: https://github.com/open-telemetry/opentelemetry-ruby/tree/master/examples
[ruby-sig]: https://github.com/open-telemetry/community#ruby-sig
[community-meetings]: https://github.com/open-telemetry/community#community-meetings
[ruby-gitter]: https://gitter.im/open-telemetry/opentelemetry-ruby
