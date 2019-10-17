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

## Release Schedule

OpenTelemetry Ruby is under active development. Our goal is to release an
_alpha_ version of the library at the end of September 2019. This release isn't
guaranteed to conform to a specific version of the specification, and future
releases will not attempt to maintain backwards compatibility with the alpha
release.

| Component                   | Version | Target Date       |
| --------------------------- | ------- | ----------------- |
| Tracing API                 | Alpha   | September 30 2019 |
| Tracing SDK                 | Alpha   | September 30 2019 |
| Metrics API                 | Alpha   | Unknown           |
| Metrics SDK                 | Alpha   | Unknown           |
| Jaeger Trace Exporter       | Alpha   | Unknown           |
| Prometheus Metrics Exporter | Alpha   | Unknown           |
| OpenTracing Bridge          | Alpha   | Unknown           |
| OpenCensus Bridge           | Alpha   | Unknown           |

## Useful links

- For more information on OpenTelemetry, visit: <https://opentelemetry.io/>
- For help or feedback on this project, join us on [gitter][gitter-url].

## License

Apache 2.0 - See [LICENSE][license-url] for more information.

[ci-image]: https://circleci.com/gh/open-telemetry/opentelemetry-ruby.svg?style=svg
[ci-url]: https://circleci.com/gh/open-telemetry/opentelemetry-ruby
[gitter-image]: https://badges.gitter.im/open-telemetry/opentelemetry-ruby.svg
[gitter-url]: https://gitter.im/open-telemetry/opentelemetry-ruby?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge
[issues-good-first-issue]: https://github.com/open-telemetry/opentelemetry-ruby/issues?q=is%3Aissue+is%3Aopen+label%3A%22good+first+issue%22
[issues-help-wanted]: https://github.com/open-telemetry/opentelemetry-ruby/issues?q=is%3Aissue+is%3Aopen+label%3A%22help+wanted%22
[license-image]: https://img.shields.io/badge/license-Apache_2.0-green.svg?style=flat
[license-url]: https://github.com/open-telemetry/opentelemetry-ruby/blob/master/LICENSE
[ruby-sig]: https://github.com/open-telemetry/community#ruby-sig
