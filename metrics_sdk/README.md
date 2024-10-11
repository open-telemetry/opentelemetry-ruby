# opentelemetry-metrics-sdk

The `opentelemetry-metrics-sdk` is an alpha implementation of the [OpenTelemetry Metrics SDK][metrics-sdk] for Ruby. It should be used in conjunction with the `opentelemetry-sdk` to collect, analyze and export metrics.

## What is OpenTelemetry?

[OpenTelemetry][opentelemetry-home] is an open source observability framework, providing a general-purpose API, SDK, and related tools required for the instrumentation of cloud-native software, frameworks, and libraries.

OpenTelemetry provides a single set of APIs, libraries, agents, and collector services to capture distributed traces, metrics, and logs from your application. You can analyze them using Prometheus, Jaeger, and other observability tools.

## How does this gem fit in?

Metrics is one of the core signals in OpenTelemetry. This package allows you to emit OpenTelemetry metrics using Ruby. It leverages an alpha implementation of the OpenTelemetry Metrics API. At the current stage, things may break and APIs may change. Use this tool with caution.

This gem does not have a full implementation of the Metrics SDK specification. The work is in progress.

At this time, you should be able to:

* Create synchronous:
  * counters
  * up down counters
  * histograms
  * observable counters
  * observable gauges
  * observable up down counters
* Export using a pull exporter
* Use delta aggregation temporality

We do not yet have support for:

* Asynchronous instruments
* Cumulative aggregation temporality
* Metrics Views
* Metrics Exemplars
* Periodic Exporting Metric Reader
* Push metric exporting

These lists are incomplete and are intended to give a broad description of what's available.

Until the Ruby implementation of OpenTelemetry Metrics becomes stable, the functionality to create and export metrics will remain in a gem separate from the stable features available from the `opentelemetry-sdk`.

## How do I get started?

Install the gems using:

```sh
gem install opentelemetry-metrics-sdk
gem install opentelemetry-sdk
```

Or, if you use [bundler][bundler-home], include `opentelemetry-metrics-sdk` and `opentelemetry-sdk` in your `Gemfile`.

Then, configure the SDK according to your desired handling of telemetry data, and use the OpenTelemetry interfaces to produces traces and other information. Following is a basic example.

```ruby
require 'opentelemetry/sdk'
require 'opentelemetry-metrics-sdk'

# Configure the sdk with default export and context propagation formats.
OpenTelemetry::SDK.configure

# Create an exporter. This example exports metrics to the console.
console_metric_exporter = OpenTelemetry::SDK::Metrics::Export::ConsoleMetricPullExporter.new

# Add the exporter to the meter provider as a new metric reader.
OpenTelemetry.meter_provider.add_metric_reader(console_metric_exporter)

# Create a meter to generate instruments.
meter = OpenTelemetry.meter_provider.meter("SAMPLE_METER_NAME")

# Create an instrument.
histogram = meter.create_histogram('histogram', unit: 'smidgen', description: 'desscription')

# Record a metric.
histogram.record(123, attributes: {'foo' => 'bar'})

# Send the recorded metrics to the metric readers.
OpenTelemetry.meter_provider.metric_readers.each(&:pull)

# Shut down the meter provider.
OpenTelemetry.meter_provider.shutdown
```

For additional examples, see the [examples on github][examples-github].

## How can I get involved?

The `opentelemetry-metrics-sdk` gem source is [on github][repo-github], along with related gems including `opentelemetry-sdk`.

The OpenTelemetry Ruby gems are maintained by the OpenTelemetry Ruby special interest group (SIG). You can get involved by joining us in [GitHub Discussions][discussions-url] or attending our weekly meeting. See the [meeting calendar][community-meetings] for dates and times. For more information on this and other language SIGs, see the OpenTelemetry [community page][ruby-sig].

There's still work to be done, to get to a spec-compliant metrics implementation and we'd love to have more folks contributing to the project. Check the [repo][repo-github] for issues and PRs labeled with `metrics` to see what's available.

## Feedback

During this experimental stage, we're looking for lots of community feedback about this gem. Please add your comments to Issue [#1662][1662].

## License

The `opentelemetry-metrics-sdk` gem is distributed under the Apache 2.0 license. See [LICENSE][license-github] for more information.

[metrics-sdk]: https://opentelemetry.io/docs/specs/otel/metrics/sdk/
[opentelemetry-home]: https://opentelemetry.io
[bundler-home]: https://bundler.io
[repo-github]: https://github.com/open-telemetry/opentelemetry-ruby
[license-github]: https://github.com/open-telemetry/opentelemetry-ruby/blob/main/LICENSE
[examples-github]: https://github.com/open-telemetry/opentelemetry-ruby/tree/main/examples/
[ruby-sig]: https://github.com/open-telemetry/community#ruby-sig
[community-meetings]: https://github.com/open-telemetry/community#community-meetings
[discussions-url]: https://github.com/open-telemetry/opentelemetry-ruby/discussions
[1662]: https://github.com/open-telemetry/opentelemetry-ruby/issues/1662
