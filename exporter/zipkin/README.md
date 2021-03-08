# opentelemetry-exporter-zipkin

The `opentelemetry-exporter-zipkin` gem provides Zipkin exporters for OpenTelemetry for Ruby. Using `opentelemetry-exporter-zipkin`, an application can configure OpenTelemetry to export collected tracing data to [Zipkin][zipkin-home]. One exporter is included: the `Exporter` exports in HTTP JSON format over TCP to a Zipkin backend

## What is OpenTelemetry?

[OpenTelemetry][opentelemetry-home] is an open source observability framework, providing a general-purpose API, SDK, and related tools required for the instrumentation of cloud-native software, frameworks, and libraries.

OpenTelemetry provides a single set of APIs, libraries, agents, and collector services to capture distributed traces and metrics from your application. You can analyze them using Prometheus, Jaeger, and other observability tools.

## How does this gem fit in?

The `opentelemetry-exporter-zipkin` gem is a plugin that provides Zipkin Tracing export. To export to Zipkin, an application can include this gem along with `opentelemetry-sdk`, and configure the `SDK` to use the provided Zipkin exporter as a span processor.

Generally, *libraries* that produce telemetry data should avoid depending directly on specific exporter, deferring that choice to the application developer.

## How do I get started?

Install the gem using:

```
gem install opentelemetry-sdk
gem install opentelemetry-exporter-zipkin
```

Or, if you use [bundler][bundler-home], include `opentelemetry-sdk` in your `Gemfile`.

Then, configure the SDK to use a zipkin exporter as a span processor, and use the OpenTelemetry interfaces to produces traces and other information. Following is a basic example for the `AgentExporter`.

```ruby
require 'opentelemetry/sdk'
require 'opentelemetry/exporter/zipkin'

# Configure the sdk with custom export
OpenTelemetry::SDK.configure do |c|
  c.add_span_processor(
    OpenTelemetry::SDK::Trace::Export::BatchSpanProcessor.new(
      OpenTelemetry::Exporter::Zipkin::Exporter.new(endpoint: 'http://192.168.0.1:9411/api/v2/spans' )
    )
  )
  c.service_name = 'zipkin-example'
  c.service_version = '0.15.0'
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

## How can I configure the Zipkin exporter?

The collector exporter can be configured explicitly in code, as shown above, or via environment variables. The configuration parameters, environment variables, and defaults are shown below.

| Parameter   | Environment variable                  | Default                    |
| ----------- | --------------------------------------| -------------------------- |
| `endpoint:` | `OTEL_EXPORTER_ZIPKIN_ENDPOINT`       | `"http://localhost:9411"`  |
| `headers:`  | `OTEL_EXPORTER_ZIPKIN_TRACES_HEADERS` | `nil`                      |
| `timeoout:` | `OTEL_EXPORTER_ZIPKIN_TRACES_TIMEOUT` | `10`                       |
|             | `OTEL_TRACES_EXPORTER`                | `zipkin`                   |

## How can I get involved?

The `opentelemetry-exporter-zipkin` gem source is [on github][repo-github], along with related gems including `opentelemetry-sdk`.

The OpenTelemetry Ruby gems are maintained by the OpenTelemetry-Ruby special interest group (SIG). You can get involved by joining us on  in [GitHub Discussions][discussions-url]  or attending our weekly meeting. See the [meeting calendar][community-meetings] for dates and times. For more information on this and other language SIGs, see the OpenTelemetry [community page][ruby-sig].

## License

The `opentelemetry-exporter-zipkin` gem is distributed under the Apache 2.0 license. See [LICENSE][license-github] for more information.


[zipkin-home]: https://zipkin.io/
[opentelemetry-home]: https://opentelemetry.io
[bundler-home]: https://bundler.io
[repo-github]: https://github.com/open-telemetry/opentelemetry-ruby
[license-github]: https://github.com/open-telemetry/opentelemetry-ruby/blob/main/LICENSE
[examples-github]: https://github.com/open-telemetry/opentelemetry-ruby/tree/main/examples
[ruby-sig]: https://github.com/open-telemetry/community#ruby-sig
[community-meetings]: https://github.com/open-telemetry/community#community-meetings
[discussions-url]: https://github.com/open-telemetry/opentelemetry-ruby/discussions
