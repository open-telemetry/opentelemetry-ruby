# Release History: opentelemetry-sdk

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
