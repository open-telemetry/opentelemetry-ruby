# opentelemetry-propagator-ottrace

The `opentelemetry-propagator-ottrace` gem contains injectors and extractors for the
[OTTrace context propagation format][ottrace-spec].

## OT Trace Format

| Header Name         | Description                                                                                                                            | Required              |
| ------------------- | -------------------------------------------------------------------------------------------------------------------------------------- | --------------------- |
| `ot-tracer-traceid` | uint64 encoded as a string of 16 hex characters                                                                                        | yes                   |
| `ot-tracer-spanid`  | uint64 encoded as a string of 16 hex characters                                                                                        | yes                   |
| `ot-tracer-sampled` | boolean or bit encoded as a string with the values `'true'`,`'false'`, `'1'`, or `'0'`                                                 | no                    |
| `ot-baggage-*`      | repeated string to string key-value baggage items; keys are prefixed with `ot-baggage-` and the corresponding value is the raw string. | if baggage is present |

### Sampled Flag vs Bit

The `ot-tracer-sampled` header is a `boolean` encoded string however the Golang SDK incorrectly sets the `ot-tracer-sampled` header to a `bit` flag.
This and other language SDKs compensate for this by supporting both a `bit` and `boolean` encoded strings upon extraction:

- [Java](https://github.com/open-telemetry/opentelemetry-java/blob/9cea4ef1f92d3186b1bd8296e9daac4281c0f759/extensions/trace-propagators/src/main/java/io/opentelemetry/extension/trace/propagation/Common.java#L41)
- [Golang](https://github.com/open-telemetry/opentelemetry-go-contrib/blob/b72c2cd63b9a9917554cbcd709e61f5d8541eea5/propagators/ot/ot_propagator.go#L118)

This issue was [fixed](https://github.com/open-telemetry/opentelemetry-go-contrib/pull/1358) however this SDK supports both for backward compatibility with older versions of the Golang propagator.

### Interop and trace ids

The OT trace propagation format expects trace ids to be 64-bits. In order to
interop with OpenTelemetry, trace ids need to be truncated to 64-bits before
sending them on the wire. When truncating, the least significant (right-most)
bits MUST be retained. For example, a trace id of
`3c3039f4d78d5c02ee8e3e41b17ce105` would be truncated to `ee8e3e41b17ce105`.

### Baggage Notes

Baggage keys and values are validated according to [rfc7230][rfc7230-url]. Any
keys or values that would result in invalid HTTP headers will be silently
dropped during inject.

OT Baggage is represented as multiple headers where the
names are carrier dependent. For this reason, they are omitted from the `fields`
method. This behavior should be taken into account if your application relies
on the `fields` functionality. See the [specification][fields-spec-url] for
more details.

## What is OpenTelemetry?

[OpenTelemetry][opentelemetry-home] is an open source observability framework, providing a general-purpose API, SDK, and related tools required for the instrumentation of cloud-native software, frameworks, and libraries.

OpenTelemetry provides a single set of APIs, libraries, agents, and collector services to capture distributed traces and metrics from your application. You can analyze them using Prometheus, Jaeger, and other observability tools.

## How does this gem fit in?

This gem can be used with any OpenTelemetry SDK implementation. This can be the official `opentelemetry-sdk` gem or any other concrete implementation.

## How do I get started?

Install the gem using:

```
gem install opentelemetry-propagator-ottrace
```

Or, if you use [bundler][bundler-home], include `opentelemetry-propagator-ottrace` in your `Gemfile`.

Configure your application to use this propagator by setting the following [environment variable][envars]:

```
OTEL_PROPAGATORS=ottrace
```

## How can I get involved?

The `opentelemetry-propagator-ottrace` gem source is [on github][repo-github], along with related gems including `opentelemetry-api` and `opentelemetry-sdk`.

The OpenTelemetry Ruby gems are maintained by the OpenTelemetry-Ruby special interest group (SIG). You can get involved by joining us in [GitHub Discussions][discussions-url] or attending our weekly meeting. See the [meeting calendar][community-meetings] for dates and times. For more information on this and other language SIGs, see the OpenTelemetry [community page][ruby-sig].

## License

The `opentelemetry-propagator-ottrace` gem is distributed under the Apache 2.0 license. See [LICENSE][license-github] for more information.

[opentelemetry-home]: https://opentelemetry.io
[bundler-home]: https://bundler.io
[repo-github]: https://github.com/open-telemetry/opentelemetry-ruby
[license-github]: https://github.com/open-telemetry/opentelemetry-ruby/blob/main/LICENSE
[ruby-sig]: https://github.com/open-telemetry/community#ruby-sig
[community-meetings]: https://github.com/open-telemetry/community#community-meetings
[discussions-url]: https://github.com/open-telemetry/opentelemetry-ruby/discussions
[ottrace-spec]: https://github.com/opentracing/specification/blob/master/rfc/trace_identifiers.md
[rfc7230-url]: https://tools.ietf.org/html/rfc7230#section-3.2
[fields-spec-url]: https://github.com/open-telemetry/opentelemetry-specification/blob/master/specification/context/api-propagators.md#fields
[envars]: https://github.com/open-telemetry/opentelemetry-specification/blob/main/specification/sdk-environment-variables.md#general-sdk-configuration
