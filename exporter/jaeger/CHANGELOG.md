# Release History: opentelemetry-exporter-jaeger

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
