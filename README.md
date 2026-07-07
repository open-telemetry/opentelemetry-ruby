# OpenTelemetry Ruby

[![Slack channel][slack-image]][slack-url]
[![GitHub Discussions][discussions-image]][discussions-url]
[![CI][ci-image]][ci-url]
[![Apache License][license-image]][license-image]
[![OpenSSF Scorecard for opentelemetry-ruby-contrib][openssf-scorecard-image]][openssf-scorecard-url]
[![FOSSA License Status][fossa-license-image]][fossa-license-url]
[![FOSSA Security Status][fossa-security-image]][fossa-security-url]

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

### Maintainers

- [Daniel Azuma](https://github.com/dazuma), Google
- [Francis Bogsanyi](https://github.com/fbogsany), Shopify
- [Kayla Reopelle](https://github.com/kaylareopelle), New Relic
- [Matthew Wear](https://github.com/mwear), Dash0
- [Robert Laurin](https://github.com/robertlaurin), Shopify

For more information about the maintainer role, see the [community repository](https://github.com/open-telemetry/community/blob/main/guides/contributor/membership.md#maintainer).

### Approvers

- [Robb Kidd](https://github.com/robbkidd), Honeycomb
- [Xuan Cao](https://github.com/xuan-cao-swi), Solarwinds

For more information about the approver role, see the [community repository](https://github.com/open-telemetry/community/blob/main/guides/contributor/membership.md#approver).

### Emeritus

- [Andrew Hayworth](https://github.com/ahayworth), Approver
- [Ariel Valentin](https://github.com/arielvalentin), Approver
- [Eric Mustin](https://github.com/ericmustin), Approver
- [Sam Handler](https://github.com/plantfansam), Approver

For more information about the emeritus role, see the
[community repository](https://github.com/open-telemetry/community/blob/main/guides/contributor/membership.md#emeritus-maintainerapprovertriager).

### Thanks to all the people who have contributed

[![contributors](https://contributors-img.web.app/image?repo=open-telemetry/opentelemetry-ruby)](https://github.com/open-telemetry/opentelemetry-ruby/graphs/contributors)

## Contrib Repository

The [opentelemetry-ruby-contrib repository][contrib-repo] contains instrumentation libraries for many popular Ruby gems, including Rails, Rack, Sinatra, and others, so you can start using OpenTelemetry with minimal changes to your application. See the [contrib README][contrib-repo] for more details.

## Versioning

OpenTelemetry Ruby follows the [versioning and stability document][otel-versioning] in the OpenTelemetry specification. Notably, we adhere to the outlined version numbering exception, which states that experimental signals may have a `0.x` version number.

## Compatibility

OpenTelemetry Ruby ensures compatibility with the current supported versions of
the [Ruby language](https://www.ruby-lang.org/en/downloads/branches/).

## Useful links

- For more information on OpenTelemetry, visit: <https://opentelemetry.io/>
- For help or feedback on this project, join us in [GitHub Discussions][discussions-url].
- For more examples, check [SDK example][examples-github].

## License

Apache 2.0 - See [LICENSE][license-url] for more information.

[ci-image]: https://github.com/open-telemetry/opentelemetry-ruby/actions/workflows/ci.yml/badge.svg?event=push
[ci-url]: https://github.com/open-telemetry/opentelemetry-ruby/actions/workflows/ci.yml
[contrib-repo]: https://github.com/open-telemetry/opentelemetry-ruby-contrib
[contrib-instrumentations]: https://github.com/open-telemetry/opentelemetry-ruby-contrib/tree/main/instrumentation
[discussions-image]: https://img.shields.io/github/discussions/open-telemetry/opentelemetry-ruby?logo=github
[discussions-url]: https://github.com/open-telemetry/opentelemetry-ruby/discussions
[examples-github]: https://github.com/open-telemetry/opentelemetry-ruby/tree/main/examples
[fossa-license-image]: https://app.fossa.com/api/projects/custom%2B162%2Fgithub.com%2Fopen-telemetry%2Fopentelemetry-ruby.svg?type=shield&issueType=license
[fossa-license-url]: https://app.fossa.com/projects/custom%2B162%2Fgithub.com%2Fopen-telemetry%2Fopentelemetry-ruby?ref=badge_shield&issueType=license
[fossa-security-image]: https://app.fossa.com/api/projects/custom%2B162%2Fgithub.com%2Fopen-telemetry%2Fopentelemetry-ruby.svg?type=shield&issueType=security
[fossa-security-url]: https://app.fossa.com/projects/custom%2B162%2Fgithub.com%2Fopen-telemetry%2Fopentelemetry-ruby?ref=badge_shield&issueType=security
[getting-started]: https://opentelemetry.io/docs/languages/ruby/
[issues-good-first-issue]: https://github.com/open-telemetry/opentelemetry-ruby/issues?q=is%3Aissue+is%3Aopen+label%3A%22good+first+issue%22
[issues-help-wanted]: https://github.com/open-telemetry/opentelemetry-ruby/issues?q=is%3Aissue+is%3Aopen+label%3A%22help+wanted%22
[license-image]: https://img.shields.io/badge/license-Apache_2.0-green.svg?style=flat
[license-url]: https://github.com/open-telemetry/opentelemetry-ruby/blob/main/LICENSE
[openssf-scorecard-image]: https://api.scorecard.dev/projects/github.com/open-telemetry/opentelemetry-ruby/badge
[openssf-scorecard-url]: https://scorecard.dev/viewer/?uri=github.com/open-telemetry/opentelemetry-ruby
[ruby-sig]: https://github.com/open-telemetry/community#ruby-sig
[slack-image]: https://img.shields.io/badge/slack-@cncf/%23otel--ruby-purple.svg
[slack-url]: https://cloud-native.slack.com/archives/C01NWKKMKMY
[otel-versioning]: https://github.com/open-telemetry/opentelemetry-specification/blob/main/specification/versioning-and-stability.md
