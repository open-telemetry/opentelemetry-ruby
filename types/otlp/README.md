# opentelemetry-exporter-otlp-common

The `opentelemetry-exporter-otlp-common` gem provides a common set of utilities for the [OTLP](https://github.com/open-telemetry/opentelemetry-proto) exporters in OpenTelemetry Ruby.

## What is OpenTelemetry?

[OpenTelemetry][opentelemetry-home] is an open source observability framework, providing a general-purpose API, SDK, and related tools required for the instrumentation of cloud-native software, frameworks, and libraries.

OpenTelemetry provides a single set of APIs, libraries, agents, and collector services to capture distributed traces and metrics from your application. You can analyze them using Prometheus, Jaeger, and other observability tools.

## How does this gem fit in?

The `opentelemetry-exporter-otlp-common` gem is a set of common utilities used by OTLP exporters. To export to the OpenTelemetry Collector see our [exporters](https://github.com/open-telemetry/opentelemetry-ruby/tree/main/exporter).

### Supported protocol version

This gem supports the [v0.11.0 release](https://github.com/open-telemetry/opentelemetry-proto/releases/tag/v0.11.0) of OTLP.

## How can I get involved?

The `opentelemetry-exporter-otlp-common` gem source is [on github][repo-github], along with related gems including `opentelemetry-sdk`.

The OpenTelemetry Ruby gems are maintained by the OpenTelemetry-Ruby special interest group (SIG). You can get involved by joining us in [GitHub Discussions][discussions-url] or attending our weekly meeting. See the [meeting calendar][community-meetings] for dates and times. For more information on this and other language SIGs, see the OpenTelemetry [community page][ruby-sig].

## License

The `opentelemetry-exporter-otlp-common` gem is distributed under the Apache 2.0 license. See [LICENSE][license-github] for more information.

[opentelemetry-home]: https://opentelemetry.io
[repo-github]: https://github.com/open-telemetry/opentelemetry-ruby
[license-github]: https://github.com/open-telemetry/opentelemetry-ruby/blob/main/LICENSE
[ruby-sig]: https://github.com/open-telemetry/community#ruby-sig
[community-meetings]: https://github.com/open-telemetry/community#community-meetings
[discussions-url]: https://github.com/open-telemetry/opentelemetry-ruby/discussions
