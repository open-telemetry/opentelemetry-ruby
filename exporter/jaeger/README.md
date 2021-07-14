# opentelemetry-exporter-jaeger

The `opentelemetry-exporter-jaeger` gem provides Jaeger exporters for OpenTelemetry for Ruby. Using `opentelemetry-exporter-jaeger`, an application can configure OpenTelemetry to export collected tracing data to [Jaeger][jaeger-home]. Two exporters are included: the `AgentExporter` exports in Thrift Compact format over UDP to the Jaeger agent; and the `CollectorExporter` exports in Thrift Binary format over HTTP to the Jaeger collector.

## What is OpenTelemetry?

[OpenTelemetry][opentelemetry-home] is an open source observability framework, providing a general-purpose API, SDK, and related tools required for the instrumentation of cloud-native software, frameworks, and libraries.

OpenTelemetry provides a single set of APIs, libraries, agents, and collector services to capture distributed traces and metrics from your application. You can analyze them using Prometheus, Jaeger, and other observability tools.

## How does this gem fit in?

The `opentelemetry-exporter-jaeger` gem is a plugin that provides Jaeger Tracing export. To export to Jaeger, an application can include this gem along with `opentelemetry-sdk`, and configure the `SDK` to use the provided Jaeger exporter as a span processor.

Generally, *libraries* that produce telemetry data should avoid depending directly on specific exporter, deferring that choice to the application developer.

## How do I get started?

Install the gem using:

```
gem install opentelemetry-sdk
gem install opentelemetry-exporter-jaeger
```

Or, if you use [bundler][bundler-home], include `opentelemetry-sdk` in your `Gemfile`.

Then, configure the SDK to use a Jaeger exporter as a span processor, and use the OpenTelemetry interfaces to produces traces and other information. Following is a basic example for the `AgentExporter`.

```ruby
require 'opentelemetry/sdk'
require 'opentelemetry/exporter/jaeger'

# Configure the sdk with the Jaeger collector exporter
ENV['OTEL_TRACES_EXPORTER'] = 'jaeger'

ENV['OTEL_SERVICE_NAME'] = 'jaeger-example'
ENV['OTEL_SERVICE_VERSION'] = '0.6.0'

# The exporter will connect to localhost:6381 by default. To change:
# ENV['OTEL_EXPORTER_JAEGER_AGENT_HOST'] = 'some.other.host'
# ENV['OTEL_EXPORTER_JAEGER_AGENT_PORT'] = 12345

# The SDK reads the environment for configuration, so no additional configuration is needed:
OpenTelemetry::SDK.configure

# If you need to use the Jaeger Agent exporter, you will need to configure many things manually:
# OpenTelemetry::SDK.configure do |c|
#   c.add_span_processor(
#     OpenTelemetry::SDK::Trace::Export::BatchSpanProcessor.new(
#       OpenTelemetry::Exporter::Jaeger::AgentExporter.new(host: '127.0.0.1', port: 6831)
#     )
#   )
# end

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

## How can I configure the Jaeger exporter?

The agent exporter can be configured explicitly in code, as shown above, or via environment variables. The configuration parameters, environment variables, and defaults are shown below.

| Parameter          | Environment variable              | Default       |
| ------------------ | --------------------------------- | ------------- |
| `host:`            | `OTEL_EXPORTER_JAEGER_AGENT_HOST` | `"localhost"` |
| `port:`            | `OTEL_EXPORTER_JAEGER_AGENT_PORT` | `6831`        |
| `max_packet_size:` |                                   | 65000         |

The collector exporter can be configured explicitly in code, as shown above, or via environment variables. The configuration parameters, environment variables, and defaults are shown below.

| Parameter          | Environment variable                           | Default                    |
| ------------------ | ---------------------------------------------- | -------------------------- |
| `endpoint:`        | `OTEL_EXPORTER_JAEGER_ENDPOINT`                | `"http://localhost:14268"` |
| `username:`        | `OTEL_EXPORTER_JAEGER_USER`                    | `nil`                      |
| `password:`        | `OTEL_EXPORTER_JAEGER_PASSWORD`                | `nil`                      |
| `ssl_verify_mode:` | `OTEL_RUBY_EXPORTER_JAEGER_SSL_VERIFY_PEER` or | `OpenSSL::SSL:VERIFY_PEER` |
|                    | `OTEL_RUBY_EXPORTER_JAEGER_SSL_VERIFY_NONE`    |                            |

`ssl_verify_mode:` parameter values should be flags for server certificate verification: `OpenSSL::SSL:VERIFY_PEER` and `OpenSSL::SSL:VERIFY_NONE` are acceptable. These values can also be set using the appropriately named environment variables as shown where `VERIFY_PEER` will take precedence over `VERIFY_NONE`.  Please see [the Net::HTTP docs](https://ruby-doc.org/stdlib-2.5.1/libdoc/net/http/rdoc/Net/HTTP.html#verify_mode) for more information about these flags.

## How can I get involved?

The `opentelemetry-exporter-jaeger` gem source is [on github][repo-github], along with related gems including `opentelemetry-sdk`.

The OpenTelemetry Ruby gems are maintained by the OpenTelemetry-Ruby special interest group (SIG). You can get involved by joining us in [GitHub Discussions][discussions-url] or attending our weekly meeting. See the [meeting calendar][community-meetings] for dates and times. For more information on this and other language SIGs, see the OpenTelemetry [community page][ruby-sig].

## License

The `opentelemetry-exporter-jaeger` gem is distributed under the Apache 2.0 license. See [LICENSE][license-github] for more information.


[jaeger-home]: https://www.jaegertracing.io
[opentelemetry-home]: https://opentelemetry.io
[bundler-home]: https://bundler.io
[repo-github]: https://github.com/open-telemetry/opentelemetry-ruby
[license-github]: https://github.com/open-telemetry/opentelemetry-ruby/blob/main/LICENSE
[examples-github]: https://github.com/open-telemetry/opentelemetry-ruby/tree/main/examples
[ruby-sig]: https://github.com/open-telemetry/community#ruby-sig
[community-meetings]: https://github.com/open-telemetry/community#community-meetings
[discussions-url]: https://github.com/open-telemetry/opentelemetry-ruby/discussions
