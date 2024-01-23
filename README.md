# OpenTelemetry Ruby

[![Slack channel][slack-image]][slack-url]
[![CI][ci-image]][ci-image]
[![Apache License][license-image]][license-image]

The Ruby [OpenTelemetry](https://opentelemetry.io/) client.

- [Getting Started][getting-started]
- [Contributing](#contributing)
- [Contrib Repository](#contrib-repository)
- [Instrumentation Libraries][contrib-instrumentations]
- [Versioning](#versioning)
- [Useful links](#useful-links)
- [License](#license)

## Contributing

We'd love your help! Use tags [good first issue][issues-good-first-issue] and
[help wanted][issues-help-wanted] to get started with the project.

Please review the [contribution instructions](CONTRIBUTING.md) for important
information on setting up your environment, running the tests, and opening pull
requests.

The Ruby special interest group (SIG) meets regularly. See the OpenTelemetry
[community page][ruby-sig] repo for information on this and other language SIGs.

Approvers ([@open-telemetry/ruby-approvers](https://github.com/orgs/open-telemetry/teams/ruby-approvers)):

- [Eric Mustin](https://github.com/ericmustin)
- [Ariel Valentin](https://github.com/arielvalentin), GitHub
- [Andrew Hayworth](https://github.com/ahayworth), Shopify
- [Sam Handler](https://github.com/plantfansam), Shopify
- [Robb Kidd](https://github.com/robbkidd), Honeycomb
- [Kayla Reopelle](https://github.com/kaylareopelle), New Relic

*Find more about the approver role in [community repository](https://github.com/open-telemetry/community/blob/master/community-membership.md#approver).*

Maintainers ([@open-telemetry/ruby-maintainers](https://github.com/orgs/open-telemetry/teams/ruby-maintainers)):

- [Robert Laurin](https://github.com/robertlaurin), Shopify
- [Francis Bogsanyi](https://github.com/fbogsany), Shopify
- [Matthew Wear](https://github.com/mwear), Lightstep
- [Daniel Azuma](https://github.com/dazuma), Google

*Find more about the maintainer role in [community repository](https://github.com/open-telemetry/community/blob/master/community-membership.md#maintainer).*

## Contrib Repository

The [opentelemetry-ruby-contrib repository][contrib-repo] contains instrumentation libraries for many popular Ruby gems, including Rails, Rack, Sinatra, and others, so you can start using OpenTelemetry with minimal changes to your application. See the [contrib README][contrib-repo] for more details.

## Versioning

OpenTelemetry Ruby follows the [versioning and stability document][otel-versioning] in the OpenTelemetry specification. Notably, we adhere to the outlined version numbering exception, which states that experimental signals may have a `0.x` version number.

## Useful links

- For more information on OpenTelemetry, visit: <https://opentelemetry.io/>
- For help or feedback on this project, join us in [GitHub Discussions][discussions-url].

## License

Apache 2.0 - See [LICENSE][license-url] for more information.

[ci-image]: https://github.com/open-telemetry/opentelemetry-ruby/workflows/CI/badge.svg?event=push
[contrib-repo]: https://github.com/open-telemetry/opentelemetry-ruby-contrib
[contrib-instrumentations]: https://github.com/open-telemetry/opentelemetry-ruby-contrib/tree/main/instrumentation
[examples-github]: https://github.com/open-telemetry/opentelemetry-ruby/tree/main/examples
[getting-started]: https://opentelemetry.io/docs/languages/ruby/
[issues-good-first-issue]: https://github.com/open-telemetry/opentelemetry-ruby/issues?q=is%3Aissue+is%3Aopen+label%3A%22good+first+issue%22
[issues-help-wanted]: https://github.com/open-telemetry/opentelemetry-ruby/issues?q=is%3Aissue+is%3Aopen+label%3A%22help+wanted%22
[license-image]: https://img.shields.io/badge/license-Apache_2.0-green.svg?style=flat
[license-url]: https://github.com/open-telemetry/opentelemetry-ruby/blob/main/LICENSE
[ruby-sig]: https://github.com/open-telemetry/community#ruby-sig
[slack-image]: https://img.shields.io/badge/slack-@cncf/otel/ruby-brightgreen.svg?logo=slack
[slack-url]: https://cloud-native.slack.com/archives/C01NWKKMKMY
[discussions-url]: https://github.com/open-telemetry/opentelemetry-ruby/discussions
[otel-versioning]: https://github.com/open-telemetry/opentelemetry-specification/blob/main/specification/versioning-and-stability.md
