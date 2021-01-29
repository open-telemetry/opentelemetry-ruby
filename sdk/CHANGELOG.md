# Release History: opentelemetry-sdk

### v0.13.0 / 2021-01-29

* BREAKING CHANGE: Remove MILLIS from BatchSpanProcessor vars 

* ADDED: Process.runtime resource 
* ADDED: Provide default resource in SDK 
* FIXED: Resource.merge consistency 
* FIXED: Remove MILLIS from BatchSpanProcessor vars 

### v0.12.1 / 2021-01-13

* FIXED: Fix several BatchSpanProcessor errors related to fork safety 
* FIXED: Define default value for traceid ratio 

### v0.12.0 / 2020-12-24

* ADDED: Structured error handling 
* ADDED: Pluggable ID generation 
* FIXED: BSP dropped span buffer full reporting 
* FIXED: Implement SDK environment variables 
* FIXED: Remove incorrect TODO 

### v0.11.1 / 2020-12-16

* FIXED: BSP dropped span buffer full reporting 

### v0.11.0 / 2020-12-11

* ADDED: Metrics reporting from trace export 
* FIXED: Copyright comments to not reference year 

### v0.10.0 / 2020-12-03

* BREAKING CHANGE: Allow samplers to modify tracestate 

* FIXED: Allow samplers to modify tracestate 

### v0.9.0 / 2020-11-27

* BREAKING CHANGE: Pass full Context to samplers 
* BREAKING CHANGE: Add timeout for force_flush and shutdown 

* ADDED: Add OTEL_RUBY_BSP_START_THREAD_ON_BOOT env var 
* ADDED: Add timeout for force_flush and shutdown 
* FIXED: Signal at batch_size 
* FIXED: SDK Span.recording? after finish 
* FIXED: Pass full Context to samplers 
* DOCS: Add documentation on usage scenarios for span processors 

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
