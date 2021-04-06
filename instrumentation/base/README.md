# OpenTelemetry Base Instrumentation

The `opentelemetry-instrumentation-base` gem contains the instrumentation base class, and the instrumentation registry.  These modules provide a common interface to support the installation of auto instrumentation libraries.  The instrumentation base is responsible for adding itself to the instrumentation registry as well as providing convenience hooks for the installation process.  The instrumentation registry contains all the instrumentation to be installed during the SDK configuration process.

## How do I get started?

Install the gem using:

```
gem install opentelemetry-instrumentation-base
```

Or, if you use [bundler][bundler-home], include `opentelemetry-instrumentation-base` in your `Gemfile`.

## How can I get involved?

The `opentelemetry-instrumentation-base` gem source is [on github][repo-github], along with related gems including `opentelemetry-api` and `opentelemetry-sdk`.

The OpenTelemetry Ruby gems are maintained by the OpenTelemetry-Ruby special interest group (SIG). You can get involved by joining us in [GitHub Discussions][discussions-url] or attending our weekly meeting. See the [meeting calendar][community-meetings] for dates and times. For more information on this and other language SIGs, see the OpenTelemetry [community page][ruby-sig].

## License

The `opentelemetry-instrumentation-base` gem is distributed under the Apache 2.0 license. See [LICENSE][license-github] for more information.

[bundler-home]: https://bundler.io
[repo-github]: https://github.com/open-telemetry/opentelemetry-ruby
[license-github]: https://github.com/open-telemetry/opentelemetry-ruby/blob/main/LICENSE
[ruby-sig]: https://github.com/open-telemetry/community#ruby-sig
[community-meetings]: https://github.com/open-telemetry/community#community-meetings
[discussions-url]: https://github.com/open-telemetry/opentelemetry-ruby/discussions
