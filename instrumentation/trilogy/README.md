# OpenTelemetry Trilogy Instrumentation

The OpenTelemetry Trilogy Ruby gem provides instrumentation for [Trilogy][trilogy-home] and
was `COPY+PASTE+MODIFIED` from the [`OpenTelemetry MySQL`][opentelemetry-mysql].

Some key differences in this instrumentation are:

- `Trilogy` does not expose [`MySql#query_options`](https://github.com/brianmario/mysql2/blob/ca08712c6c8ea672df658bb25b931fea22555f27/lib/mysql2/client.rb#L78), therefore there is limited support for database semantic conventions.
- SQL Obfuscation is enabled by default to mitigate restricted data leaks.

## How do I get started?

Install the gem using:

```
gem install opentelemetry-instrumentation-trilogy
```

Or, if you use [bundler][bundler-home], include `opentelemetry-instrumentation-trilogy` in your `Gemfile`.

## Usage

To use the instrumentation, call `use` with the name of the instrumentation:

```ruby
OpenTelemetry::SDK.configure do |c|
  c.use 'OpenTelemetry::Instrumentation::Trilogy', {
    # The obfuscation of SQL in the db.statement attribute is disabled by default.
    # To enable, set db_statement to :obfuscate.
    db_statement: :obfuscate,
  }
end
```

Alternatively, you can also call `use_all` to install all the available instrumentation.

```ruby
OpenTelemetry::SDK.configure do |c|
  c.use_all
end
```

## How can I get involved?

The `opentelemetry-instrumentation-trilogy` gem source is [on github][repo-github], along with related gems including `opentelemetry-api` and `opentelemetry-sdk`.

The OpenTelemetry Ruby gems are maintained by the OpenTelemetry-Ruby special interest group (SIG). You can get involved by joining us in [GitHub Discussions][discussions-url] or attending our weekly meeting. See the [meeting calendar][community-meetings] for dates and times. For more information on this and other language SIGs, see the OpenTelemetry [community page][ruby-sig].

## License

The `opentelemetry-instrumentation-trilogy` gem is distributed under the Apache 2.0 license. See [LICENSE][license-github] for more information.

[trilogy-home]: https://github.com/github/trilogy
[bundler-home]: https://bundler.io
[repo-github]: https://github.com/open-telemetry/opentelemetry-ruby
[license-github]: https://github.com/open-telemetry/opentelemetry-ruby/blob/main/LICENSE
[ruby-sig]: https://github.com/open-telemetry/community#ruby-sig
[community-meetings]: https://github.com/open-telemetry/community#community-meetings
[discussions-url]: https://github.com/open-telemetry/opentelemetry-ruby/discussions
