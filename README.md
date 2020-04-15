# OpenTelemetry Ruby

[![Gitter chat][gitter-image]][gitter-url]
[![CircleCI][ci-image]][ci-url]
[![Apache License][license-image]][license-image]

The Ruby [OpenTelemetry](https://opentelemetry.io/) client.

## Contributing

We'd love your help! Use tags [good first issue][issues-good-first-issue] and
[help wanted][issues-help-wanted] to get started with the project.

The Ruby special interest group (SIG) meets regularly. See the OpenTelemetry
[community page][ruby-sig] repo for information on this and other language SIGs.

Approvers ([@open-telemetry/ruby-approvers](https://github.com/orgs/open-telemetry/teams/ruby-approvers)):

- [Vlad Gorodetsky](https://github.com/bai), Shopify
- [Yoshinori Kawasaki](https://github.com/luvtechno), Wantedly
- [Don Morrison](https://github.com/elskwid), Mutations

*Find more about the approver role in [community repository](https://github.com/open-telemetry/community/blob/master/community-membership.md#approver).*

Maintainers ([@open-telemetry/ruby-maintainers](https://github.com/orgs/open-telemetry/teams/ruby-maintainers)):

- [Francis Bogsanyi](https://github.com/fbogsany), Shopify
- [Matthew Wear](https://github.com/mwear), LightStep
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

The API and SDK packages are available on RubyGems.org, and can be installed via `bundle`:

```sh
bundle install opentelemetry-api
bundle install opentelemetry-sdk
```

To install development versions of these packages, follow the "Developer Setup" section (below).

## Developer Setup

1. Install Docker and Docker Compose for your operating system
1. Get the latest code for the project
1. Build the `opentelemetry/opentelemetry-ruby` image
    * `docker-compose build`
    * This makes the image available locally
1. API:
    1. Install dependencies
        * `docker-compose run api bundle install`
    1. Run the tests
        * `docker-compose run api bundle exec rake test`
1. SDK:
    1. Install dependencies
        * `docker-compose run sdk bundle install`
    1. Run the tests for the sdk
        * `docker-compose run sdk bundle exec rake test`

### Docker Services

We use Docker Compose to configure and build services used in development
and testing. See `docker-compose.yml` for specific configuration details.

The services provided are:

* `app` - main container environment scoped to the `/app` directory. Used primarily to build and tag the `opentelemetry/opentelemetry-ruby:latest` image.
* `api` - convenience environment scoped to the `api` gem in the `/app/api` directory.
* `sdk` - convenience environment scoped to the `sdk` gem in the `/app/sdk` directory.

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
  span.add_event(name: 'event in bar')
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
conform  to a specific version of the specification, and future releases will
not attempt to maintain backward compatibility with the alpha release.

| Component                       | Version       | Target Date       | Release Date      |
| ------------------------------- | ------------- | ----------------- | ----------------- |
| Tracing API                     | Alpha v0.2.0  | September 30 2019 | November 13 2019  |
| Tracing SDK                     | Alpha v0.2.0  | September 30 2019 | November 13 2019  |
| Trace Context Propagation       | Alpha v0.2.0  | September 30 2019 | November 13 2019  |
| Jaeger Trace Exporter           | Alpha v0.2.0  | September 30 2019 | November 13 2019  |
| Metrics API                     | Alpha v0.3.0  | February 24 2020  | Unknown           |
| Metrics SDK                     | Alpha v0.3.0  | February 24 2020  | Unknown           |
| Prometheus Metrics Exporter     | Alpha v0.3.0  | February 24 2020  | Unknown           |
| Correlation Context Propagation | Alpha v0.3.0  | February 24 2020  | Unknown           |
| OpenTracing Bridge              | Alpha v0.3.0  | February 24 2020  | Unknown           |
| Zipkin Trace Exporter           | Unknown       | Unknown           | Unknown           |
| OpenCensus Bridge               | Unknown       | Unknown           | Unknown           |

## Release Process

To perform a release of one of the OpenTelemetry Rubygems, follow these steps.
Only a maintainer may perform a release.

1. Make sure the library's `VERSION` constant matches the version to be
   released. This constant is defined in the library's `version.rb` file.
2. Add an entry to the library's `CHANGELOG.md`.
3. Tag the commit to be released. The tag must be of the form:
   `{library-name}/v{version}`. For example, to release `opentelemetry-api`
   version `1.2.3`, create the tag `opentelemetry-api/v1.2.3`.
4. Push the tag directly to Github.
5. See [here][opentelemetry-adapters-all-publishing] for special instructions
   for publishing the opentelemetry-adapters-all gem.

After the tag is pushed, CircleCI will run the release workflow. This workflow
includes one final run of the unit tests, followed by the release script itself.

The [CircleCI project](https://circleci.com/gh/open-telemetry/opentelemetry-ruby)
includes two environment variables that control the release process.

* `OPENTELEMETRY_RUBYGEMS_API_KEY` contains the API key used to authenticate
  with Rubygems for release.
* `OPENTELEMETRY_RELEASES_ENABLED` controls whether releases are enabled. If set
  to `true`, releases are performed normally. If set to `false` or unset, the
  release pipeline will execute, but the final `gem push` is disabled.

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
[opentelemetry-adapters-all-publishing]: https://github.com/open-telemetry/opentelemetry-ruby/tree/master/adapters/all#publishing
