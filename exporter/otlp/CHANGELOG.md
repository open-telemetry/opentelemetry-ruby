# Release History: opentelemetry-exporter-otlp

### v0.20.3 / 2021-08-19

* FIXED: OTLP exporter missing failure metrics 

### v0.20.2 / 2021-08-12

* FIXED: Add rescue for OpenSSL errors during export 
* DOCS: Update docs to rely more on environment variable configuration 

### v0.20.1 / 2021-06-29

* FIXED: Otlp encoding exceptions again 

### v0.20.0 / 2021-06-23

* BREAKING CHANGE: Total order constraint on span.status= 

* FIXED: Total order constraint on span.status= 

### v0.19.0 / 2021-06-03

* ADDED: Add a SSL verify mode option for the OTLP exporter 
* FIXED: Handle OTLP exporter encoding exceptions 
* DOCS: Remove the OTLP receiver legacy gRPC port(55680) references 

### v0.18.0 / 2021-05-21

* BREAKING CHANGE: Replace Time.now with Process.clock_gettime 

* FIXED: Replace Time.now with Process.clock_gettime 
* FIXED: Rescue missed otlp exporter network errors 

### v0.17.0 / 2021-04-22

* ADDED: Add zipkin exporter 

### v0.16.0 / 2021-03-17

* BREAKING CHANGE: Implement Exporter#force_flush 

* ADDED: Implement Exporter#force_flush 
* FIXED: Rescue socket err in otlp exporter to prevent failures unable to  connect 
* DOCS: Replace Gitter with GitHub Discussions 

### v0.15.0 / 2021-02-18

* BREAKING CHANGE: Streamline processor pipeline 

* ADDED: Add otlp exporter hooks 
* FIXED: Streamline processor pipeline 

### v0.14.0 / 2021-02-03

* (No significant changes)

### v0.13.0 / 2021-01-29

* BREAKING CHANGE: Spec compliance for OTLP exporter 

* ADDED: Add untraced wrapper to common utils 
* FIXED: Spec compliance for OTLP exporter 
* FIXED: Conditionally append path to collector endpoint 
* FIXED: OTLP path should be /v1/traces 
* FIXED: Rename OTLP env vars SPAN -> TRACES 

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
