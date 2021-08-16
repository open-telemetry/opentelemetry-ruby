# Release History: opentelemetry-exporter-jaeger

### v0.20.0 / 2021-08-12

* ADDED: OTEL_EXPORTER_JAEGER_TIMEOUT env var 
* DOCS: Update docs to rely more on environment variable configuration 

### v0.19.0 / 2021-06-23

* BREAKING CHANGE: Total order constraint on span.status= 

* FIXED: Total order constraint on span.status= 

### v0.18.0 / 2021-05-21

* BREAKING CHANGE: Replace Time.now with Process.clock_gettime 

* ADDED: Export to jaeger collectors w/ self-signed certs 
* FIXED: Replace Time.now with Process.clock_gettime 
* FIXED: Rename constant to hide warning message 
* FIXED: Index a link trace_id in middle rather than end 

### v0.17.0 / 2021-04-22

* ADDED: Add zipkin exporter 

### v0.16.0 / 2021-03-17

* BREAKING CHANGE: Implement Exporter#force_flush 

* ADDED: Implement Exporter#force_flush 
* DOCS: Replace Gitter with GitHub Discussions 

### v0.15.0 / 2021-02-18

* BREAKING CHANGE: Streamline processor pipeline 

* FIXED: Streamline processor pipeline 

### v0.14.0 / 2021-02-03

* (No significant changes)

### v0.13.0 / 2021-01-29

* ADDED: Provide default resource in SDK 
* ADDED: Add untraced wrapper to common utils 
* FIXED: Jaeger ref type should be FOLLOWS_FROM 

### v0.12.0 / 2020-12-24

* ADDED: Structured error handling 

### v0.11.0 / 2020-12-11

* FIXED: Copyright comments to not reference year 

### v0.10.0 / 2020-12-03

* (No significant changes)

### v0.9.0 / 2020-11-27

* BREAKING CHANGE: Add timeout for force_flush and shutdown 

* ADDED: Add timeout for force_flush and shutdown 

### v0.8.0 / 2020-10-27

* BREAKING CHANGE: Move context/span methods to Trace module 
* BREAKING CHANGE: Remove 'canonical' from status codes 
* BREAKING CHANGE: Assorted SpanContext fixes 

* FIXED: Move context/span methods to Trace module 
* FIXED: Remove 'canonical' from status codes 
* FIXED: Assorted SpanContext fixes 

### v0.7.0 / 2020-10-07

* ADDED: Add service_version setter to configurator 
* FIXED: Update IL attribute naming convention to match spec 
* DOCS: Standardize toplevel docs structure and readme 
* DOCS: Use BatchSpanProcessor in examples 

### v0.6.0 / 2020-09-10

* This gem was renamed from `opentelemetry-exporters-jaeger`.
