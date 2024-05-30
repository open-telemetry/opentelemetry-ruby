# OpenTelemetry Ruby Metrics SDK Example

### metrics_collect.rb

Running the script to see the metric data from console

```sh
ruby metrics_collect.rb
```

### metrics_collect_otlp.rb

**WARN: this example doesn't work on alpine aarch64 container due to grpc installation issue.**

This example test both metrics sdk and metrics otlp http exporter.

You can view the metrics in your favored backend (e.g. jaeger).

#### 1. Setup the local opentelemetry-collector.

e.g.
```sh
docker pull otel/opentelemetry-collector
docker run --rm -v $(pwd)/config.yaml:/etc/otel/config.yaml -p 4317:4317 -p 4318:4318 otel/opentelemetry-collector --config /etc/otel/config.yaml
```
Sample config.yaml
```yaml
receivers:
  otlp:
    protocols:
      grpc:
      http:
      # Default endpoints: 0.0.0.0:4317 for gRPC and 0.0.0.0:4318 for HTTP

exporters:
  logging:
    loglevel: debug

processors:
  batch:

service:
  pipelines:
    traces:
      receivers: [otlp]
      processors: [batch]
      exporters: [logging]
    metrics:
      receivers: [otlp]
      processors: [batch]
      exporters: [logging]
```

More information on how to setup the otel collector in [quick start](https://opentelemetry.io/docs/collector/quick-start/).

#### 2. Assign endpoint value to destinated address

e.g.
```
# Using environment variable
ENV['OTEL_EXPORTER_OTLP_METRICS_ENDPOINT'] = 'http://host.docker.internal:4318/v1/metrics'

# Or using export command
export OTEL_EXPORTER_OTLP_METRICS_ENDPOINT=http://host.docker.internal:4318/v1/metrics
```

#### 3. Running the script to send metric data to otlp collector

```sh
ruby metrics_collect_otlp.rb
```

You should see the metric data appearing in the collector.
