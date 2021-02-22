# OpenTelemetry Faraday Instrumentation

The OpenTelemetry Faraday Ruby gem is a community maintained instrumentation for [Faraday][faraday-home]. This is an HTTP client library that provides a common interface over many adaptors, such as Net::HTTP.

## How do I get started?

Install the gem using:

```
gem install opentelemetry-instrumentation-faraday
```

Or, if you use [bundler][bundler-home], include `opentelemetry-instrumentation-faraday` in your `Gemfile`.

## Usage

To install the instrumentation, call `use` with the name of the instrumentation.

```ruby
OpenTelemetry::SDK.configure do |c|
  c.use 'OpenTelemetry::Instrumentation::Faraday'
end
```

Alternatively, you can also call `use_all` to install all the available instrumentation.

```ruby
OpenTelemetry::SDK.configure do |c|
  c.use_all
end
```

## Examples

Example usage of faraday can be seen in the `./example/faraday.rb` file [here](https://github.com/open-telemetry/opentelemetry-ruby/blob/main/instrumentation/faraday/example/faraday.rb)

## How can I get involved?

The `opentelemetry-instrumentation-faraday` gem source is [on github][repo-github], along with related gems including `opentelemetry-api` and `opentelemetry-sdk`.

The OpenTelemetry Ruby gems are maintained by the OpenTelemetry-Ruby special interest group (SIG). You can get involved by joining us in [GitHub Discussions][discussions-url] or attending our weekly meeting. See the [meeting calendar][community-meetings] for dates and times. For more information on this and other language SIGs, see the OpenTelemetry [community page][ruby-sig].

## License

Apache 2.0 license. See [LICENSE][license-github] for more information.

[faraday-home]: https://github.com/lostisland/faraday
[bundler-home]: https://bundler.io
[repo-github]: https://github.com/open-telemetry/opentelemetry-ruby
[license-github]: https://github.com/open-telemetry/opentelemetry-ruby/blob/main/LICENSE
[ruby-sig]: https://github.com/open-telemetry/community#ruby-sig
[community-meetings]: https://github.com/open-telemetry/community#community-meetings
[discussions-url]: https://github.com/open-telemetry/opentelemetry-ruby/discussions
