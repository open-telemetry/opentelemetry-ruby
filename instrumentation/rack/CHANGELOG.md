# Release History: opentelemetry-instrumentation-rack

### v0.20.1 / 2021-12-01

* FIXED: [Instruentation Rack] Log content type http header 
* FIXED: Use monotonic clock where possible 
* FIXED: Rack to stop using api env getter 

### v0.20.0 / 2021-10-06

* FIXED: Prevent high cardinality rack span name as a default [#973](https://github.com/open-telemetry/opentelemetry-ruby/pull/973)

The default was to set the span name as the path of the request, we have
corrected this as it was not adhering to the spec requirement using low
cardinality span names.  You can restore the previous behaviour of high
cardinality span names by passing in a url quantization function that
forwards the uri path.  More details on this is available in the readme.

### v0.19.3 / 2021-09-29

* (No significant changes)

### v0.19.2 / 2021-08-18

* FIXED: Rack middleware assuming script_name presence 

### v0.19.1 / 2021-08-12

* DOCS: Update docs to rely more on environment variable configuration 

### v0.19.0 / 2021-06-23

* BREAKING CHANGE: Total order constraint on span.status= 

* ADDED: Add Tracer.non_recording_span to API 
* FIXED: Total order constraint on span.status= 

### v0.18.0 / 2021-05-21

* ADDED: Updated API depedency for 1.0.0.rc1
* FIXED: Removed http.status_text attribute #750

### v0.17.0 / 2021-04-22

* (No significant changes)

### v0.16.0 / 2021-03-17

* BREAKING CHANGE: Pass env to url quantization rack config to allow more flexibility

* ADDED: Pass env to url quantization rack config to allow more flexibility
* ADDED: Add rack instrumentation config option to accept callable to filter requests to trace
* FIXED: Example scripts now reference local common lib
* DOCS: Replace Gitter with GitHub Discussions

### v0.15.0 / 2021-02-18

* ADDED: Add instrumentation config validation

### v0.14.0 / 2021-02-03

* BREAKING CHANGE: Replace getter and setter callables and remove rack specific propagators

* ADDED: Replace getter and setter callables and remove rack specific propagators
* ADDED: Add untraced endpoints config to rack middleware

### v0.13.0 / 2021-01-29

* FIXED: Only include user agent when present

### v0.12.0 / 2020-12-24

* (No significant changes)

### v0.11.0 / 2020-12-11

* FIXED: Copyright comments to not reference year

### v0.10.1 / 2020-12-09

* FIXED: Rack current_span

### v0.10.0 / 2020-12-03

* (No significant changes)

### v0.9.0 / 2020-11-27

* BREAKING CHANGE: Add timeout for force_flush and shutdown

* ADDED: Instrument rails
* ADDED: Add timeout for force_flush and shutdown

### v0.8.0 / 2020-10-27

* BREAKING CHANGE: Move context/span methods to Trace module
* BREAKING CHANGE: Remove 'canonical' from status codes

* FIXED: Move context/span methods to Trace module
* FIXED: Remove 'canonical' from status codes

### v0.7.0 / 2020-10-07

* FIXED: Remove superfluous file from Rack gem
* DOCS: Added README for Rack Instrumentation
* DOCS: Standardize toplevel docs structure and readme

### v0.6.0 / 2020-09-10

* (No significant changes)
