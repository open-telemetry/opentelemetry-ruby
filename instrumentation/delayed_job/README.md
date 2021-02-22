# OpenTelemetry DelayedJob Instrumentation

The OpenTelemetry Delayed Job Ruby gem is a community maintained instrumentation for the [Delayed Job][delayedjob-home] Ruby jobs system.

## How do I get started?

Install the gem using:

```
gem install opentelemetry-instrumentation-delayed_job
```

Or, if you use [bundler][bundler-home], include `opentelemetry-instrumentation-delayed_job` in your `Gemfile`.

## Usage

To install the instrumentation, call `use` with the name of the instrumentation.

```ruby
OpenTelemetry::SDK.configure do |c|
  c.use 'OpenTelemetry::Instrumentation::DelayedJob'
end
```

Alternatively, you can also call `use_all` to install all the available instrumentation.

```ruby
OpenTelemetry::SDK.configure do |c|
  c.use_all
end
```

## Examples

Example usage of delayed_job can be seen in the `./example/delayed_job.rb` file [here](https://github.com/open-telemetry/opentelemetry-ruby/blob/main/instrumentation/delayed_job/example/delayed_job.rb)

## How can I get involved?

The `opentelemetry-instrumentation-delayed_job` gem source is [on github][repo-github], along with related gems including `opentelemetry-api` and `opentelemetry-sdk`.

The OpenTelemetry Ruby gems are maintained by the OpenTelemetry-Ruby special interest group (SIG). You can get involved by joining us in [GitHub Discussions][discussions-url] or attending our weekly meeting. See the [meeting calendar][community-meetings] for dates and times. For more information on this and other language SIGs, see the OpenTelemetry [community page][ruby-sig].

## License

Apache 2.0 license. See [LICENSE][license-github] for more information.

[delayedjob-home]: https://github.com/collectiveidea/delayed_job
[bundler-home]: https://bundler.io
[repo-github]: https://github.com/open-telemetry/opentelemetry-ruby
[license-github]: https://github.com/open-telemetry/opentelemetry-ruby/blob/main/LICENSE
[ruby-sig]: https://github.com/open-telemetry/community#ruby-sig
[community-meetings]: https://github.com/open-telemetry/community#community-meetings
[discussions-url]: https://github.com/open-telemetry/opentelemetry-ruby/discussions
