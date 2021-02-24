# Opentelemetry::Resource::Detectors

The `opentelemetry-resource_detectors` gem provides resource detectors for OpenTelemetry.

## What is OpenTelemetry?

OpenTelemetry is an open source observability framework, providing a general-purpose API, SDK, and related tools required for the instrumentation of cloud-native software, frameworks, and libraries.

OpenTelemetry provides a single set of APIs, libraries, agents, and collector services to capture distributed traces and metrics from your application. You can analyze them using Prometheus, Jaeger, and other observability tools.

## How does this gem fit in?

The `opentelemetry-resource-detectors` gem provides a means of retrieving a resource for supported environments following the resource semantic conventions.

## How do I get started?

Install the gem using:

```
gem install opentelemetry-sdk
gem install opentelemetry-resource_detectors
```

Or, if you use Bundler, include `opentelemetry-sdk` and `opentelemetry-resource_detectors` in your `Gemfile`.

```rb
require 'opentelemetry/sdk'
require 'opentelemetry/resource/detectors'

# For a specific platform
OpenTelemetry::SDK.configure do |c|
  c.resource = OpenTelemetry::Resource::Detectors::GoogleCloudPlatform.detect
end

# Or if you would like for it to run all detectors available
OpenTelemetry::SDK.configure do |c|
  c.resource = OpenTelemetry::Resource::Detectors::AutoDetector.detect
end
```

## How can I get involved?

The `opentelemetry-resource_detectors` gem source is on github, along with related gems.

The OpenTelemetry Ruby gems are maintained by the OpenTelemetry-Ruby special interest group (SIG). You can get involved by joining us in [GitHub Discussions][discussions-url] or attending our weekly meeting. See the meeting calendar for dates and times. For more information on this and other language SIGs, see the OpenTelemetry community page.

## License

The `opentelemetry-resource_detectors` gem is distributed under the Apache 2.0 license. See LICENSE for more information.

[discussions-url]: https://github.com/open-telemetry/opentelemetry-ruby/discussions
