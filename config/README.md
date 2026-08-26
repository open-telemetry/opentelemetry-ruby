# opentelemetry-config

The `opentelemetry-config` gem provides file-based, declarative configuration of the OpenTelemetry Ruby SDK from a single YAML file. It replaces the need to write programmatic setup code for common provider and exporter patterns.

## What is OpenTelemetry?

[OpenTelemetry][opentelemetry-home] is an open source observability framework, providing a general-purpose API, SDK, and related tools required for the instrumentation of cloud-native software, frameworks, and libraries.

OpenTelemetry provides a single set of APIs, libraries, agents, and collector services to capture distributed traces, metrics, and logs from your application. You can analyze them using Prometheus, Jaeger, and other observability tools.

## How does this gem fit in?

The `opentelemetry-config` gem sits on top of the OpenTelemetry Ruby SDK. Instead of calling `OpenTelemetry::SDK.configure` with a block of Ruby code, you describe your desired configuration in a YAML file and let `opentelemetry-config` wire up all the opentelemetry components for you.

It works with:

- `opentelemetry-sdk` — Traces
- `opentelemetry-exporter-otlp` — OTLP HTTP exporter
- `opentelemetry-instrumentation-all` — Instrumentation for gems

This code is still under development and is not a complete implementation of the declarative configuration specification. Until the code becomes stable, declarative configuration functionality will live outside stable OpenTelemetry libraries.

Some features we still need to implement include:
* Configuration file precedence over environment variables
* Using declarative configuration without a call in your code
* Declarative configuration instrumentation API and SDK

This is not an exhaustive list.
## How do I get started?

Install the gem using:

```sh
gem install opentelemetry-config
```

Or, if you use [bundler][bundler-home], include `opentelemetry-config` in your `Gemfile`.

### Automatic configuration via environment variable

Set `OTEL_CONFIG_FILE` to the path of your YAML config file. Call `OpenTelemetry::Config.configure` early in your application; it installs the configured components as the global OpenTelemetry state and returns a `RubySDK` handle you can use to shut them down.

```sh
OTEL_CONFIG_FILE=/path/to/otel-config.yaml bundle exec ruby app.rb
```

```ruby
require 'opentelemetry-sdk'
require 'opentelemetry-config'

sdk = OpenTelemetry::Config.configure
at_exit { sdk.shutdown }

tracer = OpenTelemetry.tracer_provider.tracer('my_app', '1.0.0')
tracer.in_span('my-operation') do |span|
  span.set_attribute('key', 'value')
end
```

If you have a config file path at hand, call `configure_from_file` instead:

```ruby
sdk = OpenTelemetry::Config.configure_from_file('/path/to/otel-config.yaml')
```

### Parse, create, and install

`configure` is a convenience wrapper around the three [SDK operations][sdk-operations]. Call them individually when you need to inspect the configuration model or delay installing the global state:

```ruby
config = OpenTelemetry::Config.parse(ENV['OTEL_CONFIG_FILE']) # => configuration model
sdk    = OpenTelemetry::Config.create(config)                 # => RubySDK, no globals touched
OpenTelemetry::Config.install(sdk)                            # => assigns the globals
```

Or

```ruby
sdk = OpenTelemetry::Config.install(
  OpenTelemetry::Config.create(
    OpenTelemetry::Config.parse(ENV.fetch('OTEL_CONFIG_FILE', nil))
  )
)
```

## YAML configuration reference

See full configuration reference in [declarative-configuration](https://opentelemetry.io/docs/languages/sdk-configuration/declarative-configuration/).

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
cd config/example
bundle exec ruby app.rb
```

## How can I get involved?

The `opentelemetry-config` gem source is [on GitHub][repo-github], along with related gems including `opentelemetry-sdk`.

The OpenTelemetry Ruby gems are maintained by the OpenTelemetry Ruby special interest group (SIG). You can get involved by joining us in [GitHub Discussions][discussions-url] or attending our weekly meeting. See the [meeting calendar][community-meetings] for dates and times. For more information on this and other language SIGs, see the OpenTelemetry [community page][ruby-sig].

## License

The `opentelemetry-config` gem is distributed under the Apache 2.0 license. See [LICENSE][license-github] for more information.

[opentelemetry-home]: https://opentelemetry.io
[bundler-home]: https://bundler.io
[sdk-operations]: https://github.com/open-telemetry/opentelemetry-specification/blob/main/specification/configuration/sdk.md#sdk-operations
[repo-github]: https://github.com/open-telemetry/opentelemetry-ruby
[license-github]: https://github.com/open-telemetry/opentelemetry-ruby/blob/main/LICENSE
[ruby-sig]: https://github.com/open-telemetry/community#ruby-sig
[community-meetings]: https://github.com/open-telemetry/community#community-meetings
[discussions-url]: https://github.com/open-telemetry/opentelemetry-ruby/discussions
