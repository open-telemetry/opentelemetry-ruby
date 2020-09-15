# OpenTelemetry Ruby

[![Gitter chat][gitter-image]][gitter-url]
[![CircleCI][ci-image]][ci-url]
[![Apache License][license-image]][license-image]

The Ruby [OpenTelemetry](https://opentelemetry.io/) client.

## Contributing

We'd love your help! Use tags [good first issue][issues-good-first-issue] and
[help wanted][issues-help-wanted] to get started with the project.

Please review the [contribution instructions](CONTRIBUTING.md) for important
information on setting up your environment, running the tests, and opening pull
requests.

The Ruby special interest group (SIG) meets regularly. See the OpenTelemetry
[community page][ruby-sig] repo for information on this and other language SIGs.

Approvers ([@open-telemetry/ruby-approvers](https://github.com/orgs/open-telemetry/teams/ruby-approvers)):

- [Robert Laurin](https://github.com/robertlaurin), Shopify
- [Eric Mustin](https://github.com/ericmustin), Datadog

*Find more about the approver role in [community repository](https://github.com/open-telemetry/community/blob/master/community-membership.md#approver).*

Maintainers ([@open-telemetry/ruby-maintainers](https://github.com/orgs/open-telemetry/teams/ruby-maintainers)):

- [Francis Bogsanyi](https://github.com/fbogsany), Shopify
- [Matthew Wear](https://github.com/mwear), Lightstep
- [Daniel Azuma](https://github.com/dazuma), Google

*Find more about the maintainer role in [community repository](https://github.com/open-telemetry/community/blob/master/community-membership.md#maintainer).*

## Installation

This repository includes multiple installable packages. The `opentelemetry-api`
package includes abstract classes and no-op implementations that comprise the OpenTelemetry API following
[the
specification](https://github.com/open-telemetry/opentelemetry-specification).
The `opentelemetry-sdk` package is the reference implementation of the API.

Libraries that produce telemetry data should only depend on `opentelemetry-api`,
and defer the choice of the SDK to the application developer. Applications may
depend on `opentelemetry-sdk` or another package that implements the API.

**Please note** that this library is currently in _alpha_, and shouldn't be
used in production environments.

The API and SDK packages are available on RubyGems.org, and can be installed via `gem`:

```sh
gem install opentelemetry-api
gem install opentelemetry-sdk
```

or via `Bundler` by adding the following to your `Gemfile`:

```ruby
gem 'opentelemetry-api'
gem 'opentelemetry-sdk'
```
followed by:
```sh
bundle install
```

To install development versions of these packages, follow the "Developer Setup" section (below).

## Quick Start

```ruby
require 'opentelemetry/sdk'

# Configure the sdk with default export and context propagation formats
# see SDK#configure for customizing the setup
OpenTelemetry::SDK.configure

# To start a trace you need to get a Tracer from the TracerProvider
tracer = OpenTelemetry.tracer_provider.tracer('my_app_or_gem', '0.1.0')

# create a span
tracer.in_span('foo') do |span|
  # set an attribute
  span.set_attribute('platform', 'osx')
  # add an event
  span.add_event('event in bar')
  # create bar as child of foo
  tracer.in_span('bar') do |child_span|
    # inspect the span
    pp child_span
  end
end
```

See the [API Documentation](https://open-telemetry.github.io/opentelemetry-ruby/) for more
detail, and the [opentelemetry examples][examples-github] for a complete example including
context propagation.

## Release Schedule

OpenTelemetry Ruby is under active development. Below is the release schedule
for the Ruby library. The first version of the release isn't guaranteed to
conform to a specific version of the specification, and future releases will
not attempt to maintain backward compatibility with the alpha release.

| Component                       | Version       | Target Date       | Release Date      |
| ------------------------------- | ------------- | ----------------- | ----------------- |
| Tracing API                     | Alpha v0.4.0  |                   | April 16 2020     |
| Tracing SDK                     | Alpha v0.4.0  |                   | April 16 2020     |
| Trace Context Propagation       | Alpha v0.4.0  |                   | April 16 2020     |
| Jaeger Trace Exporter           | Alpha v0.4.0  |                   | April 16 2020     |
| Baggage Propagation             | Alpha v0.4.0  |                   | April 16 2020     |
| Metrics API                     | Unknown       | Unknown           | Unknown           |
| Metrics SDK                     | Unknown       | Unknown           | Unknown           |
| Prometheus Metrics Exporter     | Unknown       | Unknown           | Unknown           |
| OpenTracing Bridge              | Unknown       | Unknown           | Unknown           |
| Zipkin Trace Exporter           | Unknown       | Unknown           | Unknown           |
| OpenCensus Bridge               | Unknown       | Unknown           | Unknown           |
| Resource Auto-detection (GCP)   | Alpha v0.5.0  | July 3 2020       |                   |
| Concurrent Ruby Instrumentation | Alpha v0.4.0  |                   | April 16 2020     |
| Ethon Instrumentation           | Alpha v0.4.0  |                   | April 16 2020     |
| Excon Instrumentation           | Alpha v0.4.0  |                   | April 16 2020     |
| Faraday Instrumentation         | Alpha v0.4.0  |                   | April 16 2020     |
| MySQL2 Instrumentation          | Alpha v0.5.0  | July 3 2020       |                   |
| Net::HTTP Instrumentation       | Alpha v0.4.0  |                   | April 16 2020     |
| Rack Instrumentation            | Alpha v0.4.0  |                   | April 16 2020     |
| Redis Instrumentation           | Alpha v0.4.0  |                   | April 16 2020     |
| Restclient Instrumentation      | Alpha v0.4.0  |                   | April 16 2020     |
| Sinatra Instrumentation         | Alpha v0.4.1  |                   | June 24 2020      |
| Sidekiq Instrumentation         | Alpha v0.4.0  |                   | April 16 2020     |
| All Instrumentation Convenience | Alpha v0.4.1  |                   | June 24 2020      |

## Useful links

- For more information on OpenTelemetry, visit: <https://opentelemetry.io/>
- For help or feedback on this project, join us on [gitter][gitter-url].

## License

Apache 2.0 - See [LICENSE][license-url] for more information.

[ci-image]: https://circleci.com/gh/open-telemetry/opentelemetry-ruby.svg?style=svg
[ci-url]: https://circleci.com/gh/open-telemetry/opentelemetry-ruby
[examples-github]: https://github.com/open-telemetry/opentelemetry-ruby/tree/master/examples
[gitter-image]: https://badges.gitter.im/open-telemetry/opentelemetry-ruby.svg
[gitter-url]: https://gitter.im/open-telemetry/opentelemetry-ruby?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge
[issues-good-first-issue]: https://github.com/open-telemetry/opentelemetry-ruby/issues?q=is%3Aissue+is%3Aopen+label%3A%22good+first+issue%22
[issues-help-wanted]: https://github.com/open-telemetry/opentelemetry-ruby/issues?q=is%3Aissue+is%3Aopen+label%3A%22help+wanted%22
[license-image]: https://img.shields.io/badge/license-Apache_2.0-green.svg?style=flat
[license-url]: https://github.com/open-telemetry/opentelemetry-ruby/blob/master/LICENSE
[ruby-sig]: https://github.com/open-telemetry/community#ruby-sig
[opentelemetry-instrumentation-all-publishing]: https://github.com/open-telemetry/opentelemetry-ruby/tree/master/instrumentation/all#publishing
