# Opentelemetry::InstrumentationHelpers

The `opentelemetry-instrumentation_helpers` gem provides instrumentation helpers for OpenTelemetry.

## What is OpenTelemetry?

OpenTelemetry is an open source observability framework, providing a general-purpose API, SDK, and related tools required for the instrumentation of cloud-native software, frameworks, and libraries.

OpenTelemetry provides a single set of APIs, libraries, agents, and collector services to capture distributed traces and metrics from your application. You can analyze them using Prometheus, Jaeger, and other observability tools.

## How does this gem fit in?

The `opentelemetry-instrumentation_helpers` gem provides instrumentation helpers for http, db, cache instrumentation, etc. It depends only on the OpenTelemetry Ruby API, not the SDK.

## How do I get started?

Install the gem using:

```
gem install opentelemetry-instrumentation_helpers
```

Or, if you use Bundler, include `opentelemetry-instrumentation_helpers` in your `Gemfile`.

```rb
require 'opentelemetry/instrumentation_helpers'

<!-- # TODO: example of instrumentation helpers -->

```

## How can I get involved?

The `opentelemetry-instrumentation_helpers` gem source is on github, along with related gems.

The OpenTelemetry Ruby gems are maintained by the OpenTelemetry-Ruby special interest group (SIG). You can get involved by joining us in [GitHub Discussions][discussions-url] or attending our weekly meeting. See the meeting calendar for dates and times. For more information on this and other language SIGs, see the OpenTelemetry community page.

## License

The `opentelemetry-instrumentation_helpers` gem is distributed under the Apache 2.0 license. See LICENSE for more information.

[discussions-url]: https://github.com/open-telemetry/opentelemetry-ruby/discussions
