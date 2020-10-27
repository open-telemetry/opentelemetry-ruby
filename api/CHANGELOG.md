# Release History: opentelemetry-api

### v0.8.0 / 2020-10-27

* BREAKING CHANGE: Move context/span methods to Trace module 
* BREAKING CHANGE: Remove 'canonical' from status codes 
* BREAKING CHANGE: Assorted SpanContext fixes 

* ADDED: B3 support 
* FIXED: Move context/span methods to Trace module 
* FIXED: Remove 'canonical' from status codes 
* FIXED: Assorted SpanContext fixes 

### v0.7.0 / 2020-10-07

* FIXED: Safely navigate span variable during error cases 
* DOCS: Standardize toplevel docs structure and readme 
* DOCS: Fix param description in TextMapInjector for Baggage 

### v0.6.0 / 2020-09-10

* ADDED: Add support for OTEL_LOG_LEVEL env var
* Documented array valued attributes [#343](https://github.com/open-telemetry/opentelemetry-ruby/pull/343)
* Renamed CorrelationContext to Baggage [#338](https://github.com/open-telemetry/opentelemetry-ruby/pull/338)
* Renamed Text* to TextMap* (propagators) [#335](https://github.com/open-telemetry/opentelemetry-ruby/pull/335)
* Fixed exception semantic conventions (`span.record_error` -> `span.record_exception`) [#333](https://github.com/open-telemetry/opentelemetry-ruby/pull/333)
* Removed support for lazy event creation [#329](https://github.com/open-telemetry/opentelemetry-ruby/pull/329)
  * `name:` named parameter to `span.add_event` becomes first positional argument
  * `Event` class removed from API
* Added `hex_trace_id` and `hex_span_id` helpers to `SpanContext` [#332](https://github.com/open-telemetry/opentelemetry-ruby/pull/332)
* Added `CorrelationContext::Manager.values` method to return correlations as a `Hash` [#323](https://github.com/open-telemetry/opentelemetry-ruby/pull/323)
