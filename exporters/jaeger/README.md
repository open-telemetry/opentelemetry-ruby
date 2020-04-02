# opentelemetry-exporters-jaeger

The `opentelemetry-exporters-jaeger` gem provides a Jaeger exporter for OpenTelemetry for Ruby. Using `opentelemetry-exporters-jaeger`, an application can configure OpenTelemetry to export collected tracing data to [Jaeger][jaeger-home].

## What is OpenTelemetry?

[OpenTelemetry][opentelemetry-home] is an open source observability framework, providing a general-purpose API, SDK, and related tools required for the instrumentation of cloud-native software, frameworks, and libraries.

OpenTelemetry provides a single set of APIs, libraries, agents, and collector services to capture distributed traces and metrics from your application. You can analyze them using Prometheus, Jaeger, and other observability tools.

## How does this gem fit in?

The `opentelemetry-exporters-jaeger` gem is a plugin that provides Jaeger Tracing export. To export to Jaeger, an application can include this gem along with `opentelemetry-sdk`, and configure the `TracerFactory` to use the provided Jaeger exporter as a span processor.

Generally, *libraries* that produce telemetry data should avoid depending directly on specific exporters, deferring that choice to the application developer.

## How do I get started?

Install the gem using:

```
gem install opentelemetry-sdk
gem install opentelemetry-exporters-jaeger
```

Or, if you use [bundler][bundler-home], include `opentelemetry-sdk` in your `Gemfile`.

Then, configure the SDK to use the Jaeger exporter as a span processor, and use the OpenTelemetry interfaces to produces traces and other information. Following is a basic example.

```ruby
require 'opentelemetry/sdk'
require 'opentelemetry/exporters/jaeger'

# Create a concrete tracer factory
factory = OpenTelemetry::SDK::Trace::TracerFactory.new

# Configure the tracer factory
factory.add_span_processor(
  OpenTelemetry::SDK::Trace::Export::SimpleSpanProcessor.new(
    OpenTelemetry::Exporters::Jaeger::Exporter.new(
      service_name: 'my-service', host: 'localhost', port: 14268
    )
  )
)

# Set it as the default tracer factory
OpenTelemetry.tracer_factory = factory

# Create a trace using the factory
tracer = factory.tracer('my_app_or_gem', '1.0')

# Record spans
tracer.in_span('my_task') do |task_span|
  tracer.in_span('inner') do |inner_span|
    # Do something here
  end
end
```

For additional examples, see the [examples on github][examples-github].

## How can I get involved?

The `opentelemetry-exporters-jaeger` gem source is [on github][repo-github], along with related gems including `opentelemetry-sdk`.

The OpenTelemetry Ruby gems are maintained by the OpenTelemetry-Ruby special interest group (SIG). You can get involved by joining us on our [gitter channel][ruby-gitter] or attending our weekly meeting. See the [meeting calendar][community-meetings] for dates and times. For more information on this and other language SIGs, see the OpenTelemetry [community page][ruby-sig].

## License

The `opentelemetry-exporters-jaeger` gem is distributed under the Apache 2.0 license. See [LICENSE][license-github] for more information.


[jaeger-home]: https://www.jaegertracing.io
[opentelemetry-home]: https://opentelemetry.io
[bundler-home]: https://bundler.io
[repo-github]: https://github.com/open-telemetry/opentelemetry-ruby
[license-github]: https://github.com/open-telemetry/opentelemetry-ruby/blob/master/LICENSE
[examples-github]: https://github.com/open-telemetry/opentelemetry-ruby/tree/master/examples
[ruby-sig]: https://github.com/open-telemetry/community#ruby-sig
[community-meetings]: https://github.com/open-telemetry/community#community-meetings
[ruby-gitter]: https://gitter.im/open-telemetry/opentelemetry-ruby
