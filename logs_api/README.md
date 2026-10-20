# opentelemetry-logs-api

The `opentelemetry-logs-api` gem is an alpha implementation of the [OpenTelemetry Logs API][logs-api] for Ruby applications. When opentelemetry-logs-api is installed, instrumentation can use OpenTelemetry API methods to emit log records.

## What is OpenTelemetry?

[OpenTelemetry][opentelemetry-home] is an open source observability framework, providing a general-purpose API, SDK, and related tools required for the instrumentation of cloud-native software, frameworks, and libraries.

OpenTelemetry provides a single set of APIs, libraries, agents, and collector services to capture distributed traces, metrics, and logs from your application. You can analyze them using Prometheus, Jaeger, and other observability tools.

## How does this gem fit in?

The `opentelemetry-logs-api` gem defines the core OpenTelemetry interfaces in the form of abstract classes and no-op implementations. That is, it defines interfaces and data types sufficient for instrumentation to code against to produce log records, but does not actually collect, process, or export the data.

To collect and export log records, _applications_ should also install a concrete implementation of the API, such as the `opentelemetry-logs-sdk` gem.

This code is still under development and is not a complete implementation of the Logs API. Until the code becomes stable, Logs API functionality will live outside the `opentelemetry-api` library.

## How do I get started?

Install the gems using:

```sh
gem install opentelemetry-sdk
gem install opentelemetry-logs-sdk
```

Or, if you use [bundler][bundler-home], include `opentelemetry-sdk` and `opentelemetry-logs-sdk` in your `Gemfile`. The SDK depends on `opentelemetry-logs-api`.

Requiring `opentelemetry-logs-sdk` defines the global `OpenTelemetry.logger_provider` accessor. Requiring `opentelemetry-logs-api` on its own does not. See [Upgrading to 0.6.0](#upgrading-to-060).

```ruby
require 'opentelemetry/sdk'
require 'opentelemetry-logs-sdk'

OpenTelemetry::SDK.configure

# Obtain a logger from the global logger provider.
logger = OpenTelemetry.logger_provider.logger(name: 'my_app', version: '1.0')

# Emit a log record.
logger.on_emit(severity_text: 'INFO', body: 'Hello, world!')
```

For additional examples, see the [examples on github][examples-github].

## Upgrading to 0.6.0

The Logs API is experimental. To keep it off the public `OpenTelemetry` module until it stabilizes, `opentelemetry-logs-api` 0.6.0 no longer defines `OpenTelemetry.logger_provider` or `OpenTelemetry.logger_provider=`. `opentelemetry-logs-sdk` 0.8.0 and later define both when required.

- **Applications using `opentelemetry-logs-sdk`:** Upgrade the SDK to 0.8.0 or later. No code changes are needed.
- **Code that requires only `opentelemetry-logs-api`:** Calling `OpenTelemetry.logger_provider` raises `NoMethodError`. Require `opentelemetry-logs-sdk`, or `opentelemetry/logs/global` to define the accessors without the SDK.
- **Applications on `opentelemetry-logs-sdk` 0.7.0 or earlier:** These versions allow `opentelemetry-logs-api` 0.6.0, so bundler can pair them. A compatibility shim in the API keeps them working and logs this warning:

  ```text
  opentelemetry-logs-sdk 0.7.0 and earlier register the global logger provider through a compatibility shim in opentelemetry-logs-api. Upgrade to opentelemetry-logs-sdk 0.8.0 or later.
  ```

  The shim will be removed in a future release ([#2414][2414]). Upgrade the SDK to clear the warning.

## How can I get involved?

The `opentelemetry-logs-api` gem source is [on github][repo-github], along with related gems including `opentelemetry-logs-sdk`.

The OpenTelemetry Ruby gems are maintained by the OpenTelemetry-Ruby special interest group (SIG). You can get involved by joining us in [GitHub Discussions][discussions-url] or attending our weekly meeting. See the [meeting calendar][community-meetings] for dates and times. For more information on this and other language SIGs, see the OpenTelemetry [community page][ruby-sig].

## License

The `opentelemetry-logs-api` gem is distributed under the Apache 2.0 license. See [LICENSE][license-github] for more information.

[logs-api]: https://opentelemetry.io/docs/specs/otel/logs/api/
[opentelemetry-home]: https://opentelemetry.io
[bundler-home]: https://bundler.io
[repo-github]: https://github.com/open-telemetry/opentelemetry-ruby
[license-github]: https://github.com/open-telemetry/opentelemetry-ruby/blob/main/LICENSE
[examples-github]: https://github.com/open-telemetry/opentelemetry-ruby/tree/main/examples/logs_sdk
[ruby-sig]: https://github.com/open-telemetry/community#ruby-sig
[community-meetings]: https://github.com/open-telemetry/community#community-meetings
[discussions-url]: https://github.com/open-telemetry/opentelemetry-ruby/discussions
[2414]: https://github.com/open-telemetry/opentelemetry-ruby/issues/2414
