# OpenTelemetry Mysql2 Instrumentation

The OpenTelemetry Mysql2 Ruby gem is a community maintained instrumentation for [Mysql2][mysql2-home].

## How do I get started?

Install the gem using:

```
gem install opentelemetry-instrumentation-mysql2
```

Or, if you use [bundler][bundler-home], include `opentelemetry-instrumentation-mysql2` in your `Gemfile`.

## Usage

To use the instrumentation, call `use` with the name of the instrumentation:

```ruby
OpenTelemetry::SDK.configure do |c|
  c.use 'OpenTelemetry::Instrumentation::Mysql2'
end
```

Alternatively, you can also call `use_all` to install all the available instrumentation.

```ruby
OpenTelemetry::SDK.configure do |c|
  c.use_all
end
```

### Configuration options

```ruby
OpenTelemetry::SDK.configure do |c|
  c.use 'OpenTelemetry::Instrumentation::Mysql2', {
    # The obfuscation of SQL in the db.statement attribute is disabled by default.
    # To enable, set db_statement to :obfuscate.
    db_statement: :obfuscate,
  }
end
```

## Examples

An example of usage can be seen in [`example/mysql2.rb`](https://github.com/open-telemetry/opentelemetry-ruby/blob/main/instrumentation/mysql2/example/mysql2.rb).

## How can I get involved?

The `opentelemetry-instrumentation-mysql2` gem source is [on github][repo-github], along with related gems including `opentelemetry-api` and `opentelemetry-sdk`.

The OpenTelemetry Ruby gems are maintained by the OpenTelemetry-Ruby special interest group (SIG). You can get involved by joining us on our [gitter channel][ruby-gitter] or attending our weekly meeting. See the [meeting calendar][community-meetings] for dates and times. For more information on this and other language SIGs, see the OpenTelemetry [community page][ruby-sig].

## License

The `opentelemetry-instrumentation-mysql2` gem is distributed under the Apache 2.0 license. See [LICENSE][license-github] for more information.

[mysql2-home]: https://github.com/brianmario/mysql2
[bundler-home]: https://bundler.io
[repo-github]: https://github.com/open-telemetry/opentelemetry-ruby
[license-github]: https://github.com/open-telemetry/opentelemetry-ruby/blob/main/LICENSE
[ruby-sig]: https://github.com/open-telemetry/community#ruby-sig
[community-meetings]: https://github.com/open-telemetry/community#community-meetings
[ruby-gitter]: https://gitter.im/open-telemetry/opentelemetry-ruby
