# Opentelemetry::Resource::Detectors

The `opentelemetry-resource-detectors` gem provides resource detectors for OpenTelemetry.

## What is OpenTelemetry?

[OpenTelemetry][opentelemetry-home] is an open source observability framework, providing a general-purpose API, SDK, and related tools required for the instrumentation of cloud-native software, frameworks, and libraries.

OpenTelemetry provides a single set of APIs, libraries, agents, and collector services to capture distributed traces and metrics from your application. You can analyze them using Prometheus, Jaeger, and other observability tools.

## How does this gem fit in?

The `opentelemetry-resource-detectors` gem provides a means of retrieving a [resource](https://github.com/open-telemetry/opentelemetry-specification/blob/master/specification/resource/sdk.md) for supported environments following the [resource semantic conventions](https://github.com/open-telemetry/opentelemetry-specification/blob/master/specification/resource/semantic_conventions/README.md).

## How do I get started?

Install the gem using:

```
gem install opentelemetry-sdk
gem install opentelemetry-resource-detectors
```

Or, if you use [bundler][bundler-home], include `opentelemetry-sdk` and `opentelemetry-resource-detectors` in your `Gemfile`.

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

The `opentelemetry-resource-detectors` gem source is [on github][repo-github], along with related gems.

The OpenTelemetry Ruby gems are maintained by the OpenTelemetry-Ruby special interest group (SIG). You can get involved by joining us on our [gitter channel][ruby-gitter] or attending our weekly meeting. See the [meeting calendar][community-meetings] for dates and times. For more information on this and other language SIGs, see the OpenTelemetry [community page][ruby-sig].

## License

The `opentelemetry-resource-detectors` gem is distributed under the Apache 2.0 license. See [LICENSE][license-github] for more information.


[opentelemetry-home]: https://opentelemetry.io
[bundler-home]: https://bundler.io
[repo-github]: https://github.com/open-telemetry/opentelemetry-ruby
[license-github]: https://github.com/open-telemetry/opentelemetry-ruby/blob/master/LICENSE
[examples-github]: https://github.com/open-telemetry/opentelemetry-ruby/tree/master/examples
[ruby-sig]: https://github.com/open-telemetry/community#ruby-sig
[community-meetings]: https://github.com/open-telemetry/community#community-meetings
[ruby-gitter]: https://gitter.im/open-telemetry/opentelemetry-ruby
