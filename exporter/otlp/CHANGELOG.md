# Release History: opentelemetry-exporter-otlp

### v0.12.1 / 2021-01-13

* FIXED: Updated protobuf version dependency

### v0.12.0 / 2020-12-24

* (No significant changes)

### v0.11.0 / 2020-12-11

* BREAKING CHANGE: Implement tracestate 

* ADDED: Implement tracestate 
* ADDED: Metrics reporting from trace export 
* FIXED: Copyright comments to not reference year 

### v0.10.0 / 2020-12-03

* (No significant changes)

### v0.9.0 / 2020-11-27

* BREAKING CHANGE: Add timeout for force_flush and shutdown 

* ADDED: Add timeout for force_flush and shutdown 
* FIXED: Remove unused kwarg from otlp exporter retry 

### v0.8.0 / 2020-10-27

* BREAKING CHANGE: Move context/span methods to Trace module 
* BREAKING CHANGE: Remove 'canonical' from status codes 
* BREAKING CHANGE: Assorted SpanContext fixes 

* FIXED: Move context/span methods to Trace module 
* FIXED: Remove 'canonical' from status codes 
* FIXED: Add gzip support to OTLP exporter 
* FIXED: Assorted SpanContext fixes 

### v0.7.0 / 2020-10-07

* FIXED: OTLP parent_span_id should be nil for root 
* DOCS: Fix use of add_event in OTLP doc 
* DOCS: Standardize toplevel docs structure and readme 
* DOCS: Use BatchSpanProcessor in examples 

### v0.6.0 / 2020-09-10

* Initial release.
