# Release History: opentelemetry-sdk

### v0.8.0 / 2020-10-27

* BREAKING CHANGE: Move context/span methods to Trace module 
* BREAKING CHANGE: Remove 'canonical' from status codes 
* BREAKING CHANGE: Assorted SpanContext fixes 

* FIXED: Move context/span methods to Trace module 
* FIXED: Remove 'canonical' from status codes 
* FIXED: Assorted SpanContext fixes 

### v0.7.0 / 2020-10-07

* ADDED: Add service_name setter to configurator 
* ADDED: Add service_version setter to configurator 
* FIXED: Fork safety for batch processor 
* FIXED: Don't generate a span ID unnecessarily 
* DOCS: Fix Configurator#add_span_processor 
* DOCS: Standardize toplevel docs structure and readme 

### v0.6.0 / 2020-09-10

* BREAKING CHANGE: Rename Resource labels to attributes 
* BREAKING CHANGE: Export resource from Span/SpanData instead of library_resource
* BREAKING CHANGE: Rename CorrelationContext to Baggage
* BREAKING CHANGE: Rename Text* to TextMap* (propagators, injectors, extractors)
* BREAKING CHANGE: Rename span.record_error to span.record_exception
* BREAKING CHANGE: Update samplers to match spec
* BREAKING CHANGE: Remove support for lazy event creation

* ADDED: Add OTLP exporter
* ADDED: Add support for OTEL_LOG_LEVEL env var
* FIXED: Rename Resource labels to attributes 
* ADDED: Environment variable resource detection
* ADDED: BatchSpanProcessor environment variable support
* FIXED: Remove semver prefix
* FIXED: Docs for array valued attributes
* ADDED: Add hex_trace_id and hex_span_id helpers to SpanData
* FIXED: Fix ProbabilitySampler
* ADDED: Implement GetCorrelations
* FIXED: Change default Sampler to ParentOrElse(AlwaysOn)
* FIXED: Fix probability sampler
