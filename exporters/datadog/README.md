# opentelemetry-exporters-datadog

The `opentelemetry-exporters-datadog` gem provides a Datadog exporter for OpenTelemetry for Ruby. Using `opentelemetry-exporters-datadog`, an application can configure OpenTelemetry to export collected tracing data to [Datadog][datadog-home].

## What is OpenTelemetry?

[OpenTelemetry][opentelemetry-home] is an open source observability framework, providing a general-purpose API, SDK, and related tools required for the instrumentation of cloud-native software, frameworks, and libraries.

OpenTelemetry provides a single set of APIs, libraries, agents, and collector services to capture distributed traces and metrics from your application.

## How does this gem fit in?

The `opentelemetry-exporters-datadog` gem is a plugin that provides Datadog Tracing export. To export to Datadog, an application can include this gem along with `opentelemetry-sdk`, and configure the `SDK` to use the provided Datadog exporter as a span processor.

Generally, *libraries* that produce telemetry data should avoid depending directly on specific exporters, deferring that choice to the application developer.

## How do I get started?

Install the gem using:

```
gem install opentelemetry-sdk
gem install opentelemetry-exporters-datadog
```

Or, if you use [bundler][bundler-home], include `opentelemetry-sdk` in your `Gemfile`.

Then, configure the SDK to use the Datadog exporter as a span processor, and use the OpenTelemetry interfaces to produces traces and other information. Following is a basic example.

```ruby
require 'opentelemetry/sdk'
require 'opentelemetry/exporters/datadog'

# Configure the sdk with custom export
OpenTelemetry::SDK.configure do |c|
  c.add_span_processor(
    OpenTelemetry::SDK::Trace::Export::DatadogSpanProcessor.new(
      OpenTelemetry::Exporters::Datadog::Exporter.new(
        service_name: 'my_service', agent_url: 'http://localhost:8126'
      )
    )
  )
end

# For propagation of datadog specific distibuted tracing headers,
# add the Datadog Propagator to the list of extractors and injectors, like below

# extractors = [
#   OpenTelemetry::Trace::Propagation::TraceContext.rack_extractor,
#   OpenTelemetry::CorrelationContext::Propagation.rack_extractor,
#   OpenTelemetry::Exporters::Datadog::Propagator.new
# ]

# injectors = [
#   OpenTelemetry::Trace::Propagation::TraceContext.text_injector,
#   OpenTelemetry::CorrelationContext::Propagation.text_injector,
#   OpenTelemetry::Exporters::Datadog::Propagator.new
# ]

# OpenTelemetry.propagation.http = OpenTelemetry::Context::Propagation::CompositePropagator.new(injectors, extractors)

# To start a trace you need to get a Tracer from the TracerProvider
tracer = OpenTelemetry.tracer_provider.tracer('my_app_or_gem', '0.1.0')

# create a span
tracer.in_span('foo') do |span|
  # set an attribute
  span.set_attribute('platform', 'osx')
  # add an event
  span.add_event(name: 'event in bar')
  # create bar as child of foo
  tracer.in_span('bar') do |child_span|
    # inspect the span
    pp child_span
  end
end
```

For additional examples, see the [examples on github][examples-github].

## How can I get involved?

The `opentelemetry-exporters-datadog` gem source is [on github][repo-github], along with related gems including `opentelemetry-sdk`.

The OpenTelemetry Ruby gems are maintained by the OpenTelemetry-Ruby special interest group (SIG). You can get involved by joining us on our [gitter channel][ruby-gitter] or attending our weekly meeting. See the [meeting calendar][community-meetings] for dates and times. For more information on this and other language SIGs, see the OpenTelemetry [community page][ruby-sig].

## License

The `opentelemetry-exporter-datadog` gem is distributed under the Apache 2.0 license. See [LICENSE][license-github] for more information.


[datadog-home]: https://www.datadoghq.com
[opentelemetry-home]: https://opentelemetry.io
[bundler-home]: https://bundler.io
[repo-github]: https://github.com/open-telemetry/opentelemetry-ruby
[license-github]: https://github.com/open-telemetry/opentelemetry-ruby/blob/master/LICENSE
[examples-github]: https://github.com/open-telemetry/opentelemetry-ruby/tree/master/examples
[ruby-sig]: https://github.com/open-telemetry/community#ruby-sig
[community-meetings]: https://github.com/open-telemetry/community#community-meetings
[ruby-gitter]: https://gitter.im/open-telemetry/opentelemetry-ruby
