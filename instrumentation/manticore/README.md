# OpenTelemetry Manticore Instrumentation

The OpenTelemetry RestClient gem is a community maintained instrumentation for the [Manticore][manticore-home] library.

## How do I get started?

Install the gem using:

```
gem install opentelemetry-instrumentation-manticore
```

Or, if you use [bundler][bundler-home], include `opentelemetry-instrumentation-manticore` in your `Gemfile`.

## Usage

To install the instrumentation, call `use` with the name of the instrumentation.

```ruby
OpenTelemetry::SDK.configure do |c|
  c.use 'OpenTelemetry::Instrumentation::Manticore'
end
```

To install instrumentation with interested headers
```ruby
OpenTelemetry::SDK.configure do |c|
  c.use 'OpenTelemetry::Instrumentation::Manticore', {'record_request_headers_list'=>['Connection'], 'record_response_headers_list' => ['content-length']
  # In span, request headers conventions are logged with prefix http.request.*.
  #   Ex: http.request.connection = 'Keep-Alive'
  # In span, response headers conventions are logged with prefix http.response.*.
  #   Ex: http.response.content-length = '512'
end
```


Alternatively, you can also call `use_all` to install all the available instrumentation.

```ruby
OpenTelemetry::SDK.configure do |c|
  c.use_all
end
```

## How can I get involved?

The `opentelemetry-instrumentation-manticore` gem source is [on github][repo-github], along with related gems including `opentelemetry-api` and `opentelemetry-sdk`.

The OpenTelemetry Ruby gems are maintained by the OpenTelemetry-Ruby special interest group (SIG). You can get involved by joining us in [GitHub Discussions][discussions-url] or attending our weekly meeting. See the [meeting calendar][community-meetings] for dates and times. For more information on this and other language SIGs, see the OpenTelemetry [community page][ruby-sig].

## License

Apache 2.0 license. See [LICENSE][license-github] for more information.

[manticore-home]: https://github.com/cheald/manticore
[bundler-home]: https://bundler.io
[repo-github]: https://github.com/open-telemetry/opentelemetry-ruby
[license-github]: https://github.com/open-telemetry/opentelemetry-ruby/blob/main/LICENSE
[ruby-sig]: https://github.com/open-telemetry/community#ruby-sig
[community-meetings]: https://github.com/open-telemetry/community#community-meetings
[discussions-url]: https://github.com/open-telemetry/opentelemetry-ruby/discussions
