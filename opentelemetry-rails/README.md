# opentelemetry-rails

The `opentelemetry-rails` gem provides a minimal railtie to configure the OpenTelemetry SDK and auto instrumentation libraries in a Rails application.

## How do I get started?

Install the gem using:

```ruby
  gem install opentelemetry-rails
```

Or, if you use [bundler][bundler-home], include `opentelemetry-rails` in your `Gemfile`, e.g.

```ruby
source 'https://rubygems.org'

gem 'rails'

gem 'opentelemetry-rails'

# choose at least one exporter e.g. otlp
gem 'opentelemetry-exporter-otlp'
gem 'opentelemetry-instrumentation-all'

# or pick specific auto-instrumentation gems to enable:
# gem 'opentelemetry-instrumentation-faraday'
# gem 'opentelemetry-instrumentation-rack'
# gem 'opentelemetry-instrumentation-rails'

# ... all your gems
```

## Customizing your configuration

This gem relies [standard OpenTelemetry Environment Variables for configuration][otel-envars] but provides a minimal set of default for `OTEL_SERVICE_NAME` and `OTEL_RESOURCE_ATTRIBUTES` if left unset.

## How can I get involved?

The `opentelemetry-rails` gem source is [on github][repo-github].

The OpenTelemetry Ruby gems are maintained by the OpenTelemetry-Ruby special interest group (SIG). You can get involved by joining us in [GitHub Discussions][discussions-url] or attending our weekly meeting. See the [meeting calendar][community-meetings] for dates and times. For more information on this and other language SIGs, see the OpenTelemetry [community page][ruby-sig].

## License

The `opentelemetry` gems are distributed under the Apache 2.0 license. See [LICENSE][license-github] for more information.

[opentelemetry-home]: https://opentelemetry.io
[bundler-home]: https://bundler.io
[repo-github]: https://github.com/open-telemetry/opentelemetry-ruby
[license-github]: https://github.com/open-telemetry/opentelemetry-ruby/blob/main/LICENSE
[examples-github]: https://github.com/open-telemetry/opentelemetry-ruby/tree/main/examples
[ruby-sig]: https://github.com/open-telemetry/community#ruby-sig
[community-meetings]: https://github.com/open-telemetry/community#community-meetings
[discussions-url]: https://github.com/open-telemetry/opentelemetry-ruby/discussions
[otel-envars]: https://github.com/open-telemetry/opentelemetry-specification/blob/main/specification/sdk-environment-variables.md
