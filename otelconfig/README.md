# opentelemetry-otelconfig

The `opentelemetry-otelconfig` gem provides file-based, declarative configuration of the OpenTelemetry Ruby SDK from a single YAML file. It replaces the need to write programmatic setup code for common provider and exporter patterns.

## What is OpenTelemetry?

[OpenTelemetry][opentelemetry-home] is an open source observability framework, providing a general-purpose API, SDK, and related tools required for the instrumentation of cloud-native software, frameworks, and libraries.

OpenTelemetry provides a single set of APIs, libraries, agents, and collector services to capture distributed traces, metrics, and logs from your application. You can analyze them using Prometheus, Jaeger, and other observability tools.

## How does this gem fit in?

The `opentelemetry-otelconfig` gem sits on top of the OpenTelemetry Ruby SDK. Instead of calling `OpenTelemetry::SDK.configure` with a block of Ruby code, you describe your desired configuration in a YAML file and let `opentelemetry-otelconfig` wire up all the opentelemetry components for you.

It works with:

- `opentelemetry-sdk` — tracing
- `opentelemetry-exporter-otlp` — OTLP HTTP exporters
- `opentelemetry-instrumentation-all` — auto-instrumentation

## How do I get started?

Install the gem using:

```sh
gem install opentelemetry-otelconfig
```

Or, if you use [bundler][bundler-home], include `opentelemetry-otelconfig` in your `Gemfile`.

### Automatic configuration via environment variable

Set `OTEL_CONFIG_FILE` to the path of your YAML config file. Call `OpenTelemetry::OtelConfig.configure` early in your application; it returns a `RubySDK` value that you wire into the global OpenTelemetry state yourself.

```sh
OTEL_CONFIG_FILE=/path/to/otel-config.yaml bundle exec ruby app.rb
```

```ruby
require 'opentelemetry-sdk'
require 'opentelemetry-otelconfig'

sdk = OpenTelemetry::OtelConfig.configure
OpenTelemetry.tracer_provider = sdk.tracer_provider
OpenTelemetry.propagation = sdk.propagator if sdk&.propagator

tracer = OpenTelemetry.tracer_provider.tracer('my_app', '1.0.0')
tracer.in_span('my-operation') do |span|
  span.set_attribute('key', 'value')
end
```

If you have a config file path at hand, call `configure_from_file` instead:

```ruby
sdk = OpenTelemetry::OtelConfig.configure_from_file('/path/to/otel-config.yaml')
OpenTelemetry.tracer_provider = sdk.tracer_provider
OpenTelemetry.propagation = sdk.propagator if sdk&.propagator
```

## YAML configuration reference

See full configuration reference in [declarative-configuration](https://opentelemetry.io/docs/languages/sdk-configuration/declarative-configuration/)

### Disabling the SDK

Set `disabled: true` to keep all providers as no-ops without removing the config file. This is useful for running tests or CI pipelines without telemetry overhead.

```yaml
file_format: "1.0"
disabled: true
```

### Resource attributes

Attributes can be provided as a structured array, a comma-separated string, or both. When the same key appears in both, the `attributes` array takes priority.

```yaml
resource:
  attributes:
    - name: service.name
      value: "my-service"
    - name: deployment.environment
      value: "staging"
  attributes_list: "service.namespace=my-namespace,service.version=1.0.0"
```

### Samplers

| Sampler | YAML key |
| ------- | -------- |
| Always on | `always_on:` |
| Always off | `always_off:` |
| Trace-ID ratio | `trace_id_ratio_based: { ratio: 0.25 }` |
| Parent-based | `parent_based: { root: ... }` |

```yaml
tracer_provider:
  sampler:
    parent_based:
      root:
        trace_id_ratio_based:
          ratio: 0.1
      remote_parent_sampled:
        always_on:
      remote_parent_not_sampled:
        always_off:
      local_parent_sampled:
        always_on:
      local_parent_not_sampled:
        always_off:
```

### Propagators

Propagators can be listed either as a YAML array or as a comma-separated string.

```yaml
# Array form
propagator:
  composite:
    - tracecontext:
    - baggage:

# String form (equivalent)
propagator:
  composite_list: "tracecontext,baggage"
```

Supported propagator names: `tracecontext`, `baggage`, `b3`, `b3multi`, `jaeger`, `ottrace`, `xray`, `google_cloud_trace_context`.

### Auto-instrumentation

The `instrumentation/development` key configures auto-instrumentation. The `ruby:` sub-key maps snake_case library names to option hashes.

```yaml
instrumentation/development:
  ruby:
    net_http:
      untraced_hosts:
        - localhost
    rack:
      untraced_endpoints:
        - /healthz
```

Short names follow the snake_case convention of the instrumentation class suffix (e.g., `net_http` for `OpenTelemetry::Instrumentation::Net::HTTP`).

## Examples

A runnable example application is available in the [`example/`][example-dir] directory. It demonstrates traces configured from YAML with console output.

```sh
cd otelconfig/example
bundle exec ruby app.rb
```

## How can I get involved?

The `opentelemetry-otelconfig` gem source is [on github][repo-github], along with related gems including `opentelemetry-sdk`.

The OpenTelemetry Ruby gems are maintained by the OpenTelemetry Ruby special interest group (SIG). You can get involved by joining us in [GitHub Discussions][discussions-url] or attending our weekly meeting. See the [meeting calendar][community-meetings] for dates and times. For more information on this and other language SIGs, see the OpenTelemetry [community page][ruby-sig].

## License

The `opentelemetry-otelconfig` gem is distributed under the Apache 2.0 license. See [LICENSE][license-github] for more information.

[opentelemetry-home]: https://opentelemetry.io
[bundler-home]: https://bundler.io
[repo-github]: https://github.com/open-telemetry/opentelemetry-ruby
[license-github]: https://github.com/open-telemetry/opentelemetry-ruby/blob/main/LICENSE
[ruby-sig]: https://github.com/open-telemetry/community#ruby-sig
[community-meetings]: https://github.com/open-telemetry/community#community-meetings
[discussions-url]: https://github.com/open-telemetry/opentelemetry-ruby/discussions
