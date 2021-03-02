# OpenTelemetry GoogleApisCore Instrumentation

The GoogleApisCore instrumentation is a community-maintained instrumentation for the [google-apis-core][google-apis-core-home] gem.

## How do I get started?

Install the gem using:

```
gem install opentelemetry-instrumentation-google_apis_core
```

Or, if you use [bundler][bundler-home], include `opentelemetry-instrumentation-google_apis_core` in your `Gemfile`.

## Usage

To use the instrumentation, call `use` with the name of the instrumentation:

```ruby
OpenTelemetry::SDK.configure do |c|
  c.use 'OpenTelemetry::Instrumentation::GoogleApisCore'
end
```

Alternatively, you can also call `use_all` to install all the available instrumentation.

```ruby
OpenTelemetry::SDK.configure do |c|
  c.use_all
end
```

## Examples

Example usage can be seen in the `./example/trace_demonstration.rb` file [here](https://github.com/open-telemetry/opentelemetry-ruby/blob/main/instrumentation/google_apis_core/example/trace_demonstration.rb)

## How can I get involved?

The `opentelemetry-instrumentation-google_apis_core` gem source is [on github][repo-github], along with related gems including `opentelemetry-api` and `opentelemetry-sdk`.

The OpenTelemetry Ruby gems are maintained by the OpenTelemetry-Ruby special interest group (SIG). You can get involved by joining us on our [gitter channel][ruby-gitter] or attending our weekly meeting. See the [meeting calendar][community-meetings] for dates and times. For more information on this and other language SIGs, see the OpenTelemetry [community page][ruby-sig].

## License

The `opentelemetry-instrumentation-google_apis_core` gem is distributed under the Apache 2.0 license. See [LICENSE][license-github] for more information.

[google-apis-core-home]: https://github.com/googleapis/google-api-ruby-client/tree/master/google-apis-core
[bundler-home]: https://bundler.io
[repo-github]: https://github.com/open-telemetry/opentelemetry-ruby
[license-github]: https://github.com/open-telemetry/opentelemetry-ruby/blob/main/LICENSE
[ruby-sig]: https://github.com/open-telemetry/community#ruby-sig
[community-meetings]: https://github.com/open-telemetry/community#community-meetings
