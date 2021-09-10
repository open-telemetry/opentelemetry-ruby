# opentelemetry-propagator-xray

The `opentelemetry-propagator-xray` gem contains injectors and extractors for the
[AWS XRay propagation format][aws-xray].

## What is OpenTelemetry?

[OpenTelemetry][opentelemetry-home] is an open source observability framework, providing a general-purpose API, SDK, and related tools required for the instrumentation of cloud-native software, frameworks, and libraries.

OpenTelemetry provides a single set of APIs, libraries, agents, and collector services to capture distributed traces and metrics from your application. You can analyze them using Prometheus, Jaeger, and other observability tools.

## How does this gem fit in?

This gem can be used with any OpenTelemetry SDK implementation. This can be the official `opentelemetry-sdk` gem or any other concrete implementation.

## How do I get started?

Install the gem using:

```
gem install opentelemetry-propagator-xray
```

Or, if you use [bundler][bundler-home], include `opentelemetry-propagator-xray` in your `Gemfile`.

In your application:
```
require 'opentelemetry/propagator/xray'
# Optional
ENV['OTEL_PROPAGATORS'] ||= 'xray' # Or you can set this as an environment variable outside of the application
```

## To generate AWS XRay compliant IDs use the 'OpenTelemetry::AWSXRayTrace' module:
```
require 'opentelemetry/propagator/xray'

OpenTelemetry::SDK.configure do |c|
  c.id_generator = OpenTelemetry::Propagator::XRay::IDGenerator
end
```
The propagator and ID generation are independent and do not need to be used in conjunction but can be.

## How can I get involved?

The `opentelemetry-propagator-xray` gem source is [on github][repo-github], along with related gems including `opentelemetry-api` and `opentelemetry-sdk`.

The OpenTelemetry Ruby gems are maintained by the OpenTelemetry-Ruby special interest group (SIG). You can get involved by joining us in [GitHub Discussions][discussions-url] or attending our weekly meeting. See the [meeting calendar][community-meetings] for dates and times. For more information on this and other language SIGs, see the OpenTelemetry [community page][ruby-sig].

## License

The `opentelemetry-propagator-xray` gem is distributed under the Apache 2.0 license. See [LICENSE][license-github] for more information.

[opentelemetry-home]: https://opentelemetry.io
[bundler-home]: https://bundler.io
[repo-github]: https://github.com/open-telemetry/opentelemetry-ruby
[license-github]: https://github.com/open-telemetry/opentelemetry-ruby/blob/main/LICENSE
[ruby-sig]: https://github.com/open-telemetry/community#ruby-sig
[community-meetings]: https://github.com/open-telemetry/community#community-meetings
[discussions-url]: https://github.com/open-telemetry/opentelemetry-ruby/discussions
[aws-xray]: https://docs.aws.amazon.com/xray/latest/devguide/aws-xray.html
