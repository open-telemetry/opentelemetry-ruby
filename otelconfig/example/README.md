# Declarative Configuration Example

This example shows how to configure the OpenTelemetry SDK (tracing) from a YAML
file using the `opentelemetry-otelconfig` gem — no programmatic
`OpenTelemetry::SDK.configure` block required.

## Files

| File | Purpose |
| ---- | ------- |
| `app.rb` | Example application — emits spans |
| `otel-config-console.yaml` | console-only exporter, works without a collector |
| `otel-config.yaml` | Include otlp_http exporter, need working collector |

## Quick start (console output, no collector needed)

```sh
# From this directory
bundle install
bundle exec ruby app.rb
```

You will see span output written to stdout.

## How it works

1. Set the `OTEL_CONFIG_FILE` environment variable to the path of your YAML file.
2. `require 'opentelemetry-otelconfig'` reads the file, parses it, and wires
   up `TracerProvider`, propagators, and instrumentation — all in one step.
3. Use the standard OpenTelemetry API (`OpenTelemetry.tracer_provider`) as normal.

If `OTEL_CONFIG_FILE` is not set, call `OpenTelemetry::OtelConfig.configure`
manually with a config hash, or configure programmatically using the SDK.

## YAML config key reference

| Section | Description |
| ------- | ----------- |
| `resource.attributes` | Service name, version, environment, and any custom resource attributes |
| `resource.attributes_list` | Comma-separated `key=value` pairs as an alternative to attributes array |
| `tracer_provider.processors` | `batch` or `simple` span processors with `console` or `otlp_http` exporters |
| `tracer_provider.sampler` | `always_on`, `always_off`, `trace_id_ratio_based`, or `parent_based` |
| `tracer_provider.limits` | Attribute, event, and link count/length limits |
| `propagator.composite` | Ordered list of propagators (`tracecontext`, `baggage`, `b3`, `b3multi`, `jaeger`, `xray`) |
| `instrumentation.general` | Enabled/disabled instrumentation libraries |
