# Release History: opentelemetry-exporter-zipkin

### v0.23.1 / 2024-02-06

* FIXED: Require csv for ruby-3.4 compatibility
* DOCS: Add missing period

### v0.23.0 / 2023-06-08

* BREAKING CHANGE: Remove support for EoL Ruby 2.7 

* ADDED: Remove support for EoL Ruby 2.7 

### v0.22.0 / 2023-05-30

* ADDED: Custom  Metrics Reporter Support for Zipkin 

### v0.21.0 / 2022-09-14

* ADDED: Add dropped events/attributes/links counts to zipkin + jaeger exporters 
* ADDED: Support InstrumentationScope, and update OTLP proto to 0.18.0 

### v0.20.0 / 2022-06-09

* (No significant changes)

### v0.19.3 / 2021-12-01

* FIXED: Change net attribute names to match the semantic conventions spec for http 

### v0.19.2 / 2021-09-29

* (No significant changes)

### v0.19.1 / 2021-08-12

* DOCS: Update docs to rely more on environment variable configuration 

### v0.19.0 / 2021-06-23

* BREAKING CHANGE: Total order constraint on span.status= 

* FIXED: Total order constraint on span.status= 

### v0.18.0 / 2021-05-21

* BREAKING CHANGE: Replace Time.now with Process.clock_gettime 

* FIXED: Replace Time.now with Process.clock_gettime 

### v0.17.0 / 2021-04-22

* Initial release.
