# OpenTelemetry instrumentation libraries
 
[OpenTelemetry](https://opentelemetry.io/) is an open source observability framework, providing a general-purpose API, SDK, and related tools required for the instrumentation of cloud-native software, frameworks, and libraries.

Instrumentation libraries provide pre-built OpenTelemetry instrumentation for popular libraries: This repository contains instrumentation for Rails, Rack, Sinatra, and others.  This way you can start using OpenTelemetry with minimal changes to your application.

## How do I get started?

### Individual instrumentation libraries

Individual instrumentation libraries can be found in subdirectories under `/instrumentation` (with the exception of `all`, see below).

To get started with a single instrumentation library, for example `opentelemetry-instrumentation-rack`:

### 1. Install the gem

```
gem install opentelemetry-instrumentation-rack
```

### 2. Configure OpenTelemetry to use the instrumentation

```
OpenTelemetry::SDK.configure do |c|
  c.use 'OpenTelemetry::Instrumentation::Rack'
end
```

Instrumentation-specific documentation can be found in each subdirectory's `README.md`.

### `opentelemetry-instrumentation-all`

You also have the option of installing all of the instrumentation libraries by installing `opentelemetry-instrumentation-all`.  See that gem's [README](https://github.com/open-telemetry/opentelemetry-ruby/tree/main/instrumentation/all) for more.

## How can I get involved?

The source for all OpenTelemetry Ruby instrumentation gems is [on github](https://github.com/open-telemetry/opentelemetry-ruby/tree/main/instrumentation), along with related gems including `opentelemetry-api` and `opentelemetry-sdk`.

The OpenTelemetry Ruby gems are maintained by the OpenTelemetry-Ruby special interest group (SIG). You can get involved by joining us on our [gitter channel][ruby-gitter] or attending our weekly meeting. See the [meeting calendar][community-meetings] for dates and times. For more information on this and other language SIGs, see the OpenTelemetry [community page][ruby-sig].


## License

All OpenTelemetry Ruby instrumentation gems are distributed under the Apache 2.0 license. See [LICENSE][license-github] for more information.


[license-github]: https://github.com/open-telemetry/opentelemetry-ruby/blob/main/LICENSE
[ruby-sig]: https://github.com/open-telemetry/community#ruby-sig
[community-meetings]: https://github.com/open-telemetry/community#community-meetings
[ruby-gitter]: https://gitter.im/open-telemetry/opentelemetry-ruby


