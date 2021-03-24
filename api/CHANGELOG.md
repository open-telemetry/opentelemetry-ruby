# Release History: opentelemetry-api

### v0.16.0 / 2021-03-17

* ADDED: Span#add_attributes 
* FIXED: Handle rack env getter edge cases 
* DOCS: Replace Gitter with GitHub Discussions 

### v0.15.0 / 2021-02-18

* ADDED: Add instrumentation config validation 
* DOCS: Clarify nil attribute values not allowed 

### v0.14.0 / 2021-02-03

* BREAKING CHANGE: Replace getter and setter callables and remove rack specific propagators 

* ADDED: Replace getter and setter callables and remove rack specific propagators 

### v0.13.0 / 2021-01-29

* ADDED: Add optional attributes to record_exception 
* FIXED: Small test fixes. 

### v0.12.1 / 2021-01-13

* FIXED: Eliminate warning about Random::DEFAULT on Ruby 3.0 

### v0.12.0 / 2020-12-24

* ADDED: Structured error handling 

### v0.11.0 / 2020-12-11

* BREAKING CHANGE: Implement tracestate 

* ADDED: Implement tracestate 
* FIXED: Missing white space from install messages 
* FIXED: Copyright comments to not reference year 

### v0.10.0 / 2020-12-03

* (No significant changes)

### v0.9.0 / 2020-11-27

* (No significant changes)

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
