# opentelemetry-test-helpers

The `opentelemetry-test-helpers` gem contains a collection of test helpers for the various OpenTelemetry Ruby gems.

## What is OpenTelemetry?

[OpenTelemetry][opentelemetry-home] is an open source observability framework, providing a general-purpose API, SDK, and related tools required for the instrumentation of cloud-native software, frameworks, and libraries.

OpenTelemetry provides a single set of APIs, libraries, agents, and collector services to capture distributed traces and metrics from your application. You can analyze them using Prometheus, Jaeger, and other observability tools.

## How does this gem fit in?

The `opentelemetry-test-helpers` gem is home to commonly used snippets of test code in the OpenTelemetry Ruby gems. The intended use of this gem is to test the implementation of OpenTelemetry Ruby itself, but may be used by consumers of OpenTelemetry Ruby gems.

## How do I get started?

Install the gem using:

```sh
gem install opentelemetry-test-helpers
```

Or, if you use [bundler][bundler-home], include `opentelemetry-test-helpers` in your `Gemfile`.

## How can I get involved?

The `opentelemetry-test-helpers` gem source is [on github][repo-github], along with related gems including `opentelemetry-api`.

The OpenTelemetry Ruby gems are maintained by the OpenTelemetry-Ruby special interest group (SIG). You can get involved by joining us in [GitHub Discussions][discussions-url] or attending our weekly meeting. See the [meeting calendar][community-meetings] for dates and times. For more information on this and other language SIGs, see the OpenTelemetry [community page][ruby-sig].

## License

The `opentelemetry-test-helpers` gem is distributed under the Apache 2.0 license. See [LICENSE][license-github] for more information.

[opentelemetry-home]: https://opentelemetry.io
[bundler-home]: https://bundler.io
[repo-github]: https://github.com/open-telemetry/opentelemetry-ruby
[license-github]: https://github.com/open-telemetry/opentelemetry-ruby/blob/main/LICENSE
[ruby-sig]: https://github.com/open-telemetry/community#ruby-sig
[community-meetings]: https://github.com/open-telemetry/community#community-meetings
[discussions-url]: https://github.com/open-telemetry/opentelemetry-ruby/discussions
