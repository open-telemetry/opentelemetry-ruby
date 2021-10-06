# OpenTelemetry Rack Instrumentation

The Rack instrumentation is a community-maintained instrumentation for the [Rack][rack-home] web server interface.

## How do I get started?

Install the gem using:

```
gem install opentelemetry-instrumentation-rack
```

Or, if you use [bundler][bundler-home], include `opentelemetry-instrumentation-rack` in your `Gemfile`.

## Usage

To use the instrumentation, call `use` with the name of the instrumentation:

```ruby
OpenTelemetry::SDK.configure do |c|
  c.use 'OpenTelemetry::Instrumentation::Rack'
end
```

Alternatively, you can also call `use_all` to install all the available instrumentation.

```ruby
OpenTelemetry::SDK.configure do |c|
  c.use_all
end
```
## Controlling span name cardinality

By default we will set the rack span name to match the format "HTTP #{method}" (ie. HTTP GET). There are different ways to control span names with this instrumentation.

### Enriching rack spans

We surface a hook to easily retrieve the rack span within the context of a request so that you can add information to or rename your server span.

This is how the rails controller instrumentation is able to rename the span names to match the controller and action that process the request. See https://github.com/open-telemetry/opentelemetry-ruby/blob/f6fb025bef69f839078748f56516ce38c7d51eb8/instrumentation/action_pack/lib/opentelemetry/instrumentation/action_pack/patches/action_controller/metal.rb#L15-L16 for an example.

### High cardinality example

You can pass in an url quantization lambda that simply uses the URL path, the result is you will end up with high cardinality span names, however this may be acceptable in your deployment and is easy configurable using the following example.

```ruby
OpenTelemetry::SDK.configure do |c|
  c.use 'OpenTelemetry::Instrumentation::Rack', { url_quantization: ->(path, _env) { path.to_s } }
end
```

## Examples

Example usage can be seen in the `./example/trace_demonstration.rb` file [here](https://github.com/open-telemetry/opentelemetry-ruby/blob/main/instrumentation/rack/example/trace_demonstration.rb)

## How can I get involved?

The `opentelemetry-instrumentation-rack` gem source is [on github][repo-github], along with related gems including `opentelemetry-api` and `opentelemetry-sdk`.

The OpenTelemetry Ruby gems are maintained by the OpenTelemetry-Ruby special interest group (SIG). You can get involved by joining us in [GitHub Discussions][discussions-url] or attending our weekly meeting. See the [meeting calendar][community-meetings] for dates and times. For more information on this and other language SIGs, see the OpenTelemetry [community page][ruby-sig].

## License

The `opentelemetry-instrumentation-rack` gem is distributed under the Apache 2.0 license. See [LICENSE][license-github] for more information.

[rack-home]: https://github.com/rack/rack
[bundler-home]: https://bundler.io
[repo-github]: https://github.com/open-telemetry/opentelemetry-ruby
[license-github]: https://github.com/open-telemetry/opentelemetry-ruby/blob/main/LICENSE
[ruby-sig]: https://github.com/open-telemetry/community#ruby-sig
[community-meetings]: https://github.com/open-telemetry/community#community-meetings
[discussions-url]: https://github.com/open-telemetry/opentelemetry-ruby/discussions
