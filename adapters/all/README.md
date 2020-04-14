# opentelemetry-adapters-all

The `opentelemetry-adapters-all` gem is an all-in-one distribution of community maintained instrumentation adapters. Instrumentation adapters are packaged as individual gems for flexibility and maintainability. Instead of having to require each adapter individually, applications can depend on this all-in-one gem as a convenient alternative.

## What is OpenTelemetry?

[OpenTelemetry][opentelemetry-home] is an open source observability framework, providing a general-purpose API, SDK, and related tools required for the instrumentation of cloud-native software, frameworks, and libraries.

OpenTelemetry provides a single set of APIs, libraries, agents, and collector services to capture distributed traces and metrics from your application. You can analyze them using Prometheus, Jaeger, and other observability tools.

## How does this gem fit in?

This gem can be used with any OpenTelemetry SDK implementation. This can be the official `opentelemetry-sdk` gem or any other concrete implementation.

## How do I get started?

Install the gem using:

```
gem install opentelemetry-adapters-all
```

Or, if you use [bundler][bundler-home], include `opentelemetry-adapters-all` in your `Gemfile`.


The `opentelemetry-api` has functionality to discover the instrumentation adapters that an application depends on. It maintains a registry of discovered adapters that SDKs can use to automatically install the instrumentation for you. These instructions pertain to the offical `opentelemetry-sdk` implementation. Consult the documentation for your SDK if you are using an alternative implementation.


### Use All

The `use_all` method will install all instrumentation present for an application, where the underlying, instrumented library is also present. Per library configuration can be passed in using an optional hash argument that has the adapter names as keys and configuration hashes as values.


```ruby
require 'opentelemetry/sdk'

# install all compatible instrumentation with default configuration
OpenTelemetry::SDK.configure do |c|
  c.use_all
end
```

```ruby
require 'opentelemetry/sdk'

# install all compatible instrumentation with per adapter configuration overrides
OpenTelemetry::SDK.configure do |c|
  c.use_all('OpenTelemetry::Adapters::SomeAdapter' => { opt: 'value' })
end
```

### Selective Install

Some users may want more fine grained control over what instrumentation they install for their application. Users can opt to selectively install instrumentation with the `use` method. Call `use` with the name of the instrumentation, and an optional configuration hash.

```ruby
require 'opentelemetry/sdk'

# install all compatible instrumentation with default configuration
OpenTelemetry::SDK.configure do |c|
  c.use 'OpenTelemetry::Adapters::Sinatra'
  c.use 'OpenTelemetry::Adapters::SomeAdapter', { opt: 'value' }
end
```

## Releasing

Releasing opentelemetry-adapters-all currently requires bumping the versions for all instrumentation adapters and pushing them to
rubygems.org first. Because of this, opentelemetry-adapters-all must be the last gem to be published in the release process.

## How can I get involved?

The `opentelemetry-adapters-all` gem source is [on github][repo-github], along with related gems including `opentelemetry-api` and `opentelemetry-sdk`.

The OpenTelemetry Ruby gems are maintained by the OpenTelemetry-Ruby special interest group (SIG). You can get involved by joining us on our [gitter channel][ruby-gitter] or attending our weekly meeting. See the [meeting calendar][community-meetings] for dates and times. For more information on this and other language SIGs, see the OpenTelemetry [community page][ruby-sig].

## License

The `opentelemetry-adapters-all` gem is distributed under the Apache 2.0 license. See [LICENSE][license-github] for more information.


[opentelemetry-home]: https://opentelemetry.io
[bundler-home]: https://bundler.io
[repo-github]: https://github.com/open-telemetry/opentelemetry-ruby
[license-github]: https://github.com/open-telemetry/opentelemetry-ruby/blob/master/LICENSE
[ruby-sig]: https://github.com/open-telemetry/community#ruby-sig
[community-meetings]: https://github.com/open-telemetry/community#community-meetings
[ruby-gitter]: https://gitter.im/open-telemetry/opentelemetry-ruby
