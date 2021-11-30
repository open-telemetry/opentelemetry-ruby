---
title: Context Propagation
weight: 2
---

> Distributed Tracing tracks the progression of a single Request, called a Trace, as it is handled by Services that make up an Application. A Distributed Trace transverses process, network and security boundaries. [Glossary][]

This requires _context propagation_, a mechanism where identifiers for a trace are sent to remote processes.

> &#8505; The OpenTelemetry Ruby SDK will take care of context propagation as long as your service is leveraging auto-instrumented libraries. Please refer to the [README][auto-instrumentation] for more details.

In order to propagate trace context over the wire, a propagator must be registered with the OpenTelemetry SDK.
The W3 TraceContext and Baggage propagators are configured by default.
Operators may override this value by setting `OTEL_PROPAGATORS` environment variable to a comma separated list of [propagators][propagators].
For example, to add B3 propagation, set `OTEL_PROPAGATORS` to the complete list of propagation formats you wish to support:

```sh
export OTEL_PROPAGATORS=tracecontext,baggage,b3
```

Propagators other than `tracecontext` and `baggage` must be added as gem dependencies to your Gemfile, e.g.:

```ruby
gem 'opentelemetry-propagator-b3'
```

[glossary]: /docs/concepts/glossary/
[propagators]: https://github.com/open-telemetry/opentelemetry-ruby/tree/main/propagator
[auto-instrumentation]: https://github.com/open-telemetry/opentelemetry-ruby/tree/main/instrumentation
