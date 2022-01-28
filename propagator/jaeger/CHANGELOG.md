# Release History: opentelemetry-propagator-jaeger

### v0.19.3 / 2021-12-01

* FIXED: Deprecate api rack env getter 

### v0.19.2 / 2021-09-29

* (No significant changes)

### v0.19.1 / 2021-08-12

* (No significant changes)

### v0.19.0 / 2021-06-23

* BREAKING CHANGE: Refactor Baggage to remove Noop* 

* ADDED: Add Tracer.non_recording_span to API 
* FIXED: Refactor Baggage to remove Noop* 

### v0.18.0 / 2021-05-21

* ADDED: Updated API depedency for 1.0.0.rc1

### v0.17.0 / 2021-04-22

* BREAKING CHANGE: Replace TextMapInjector/TextMapExtractor pairs with a TextMapPropagator.

  [Check the propagator documentation](https://open-telemetry.github.io/opentelemetry-ruby/) for the new usage.

* FIXED: Refactor propagators to add #fields

### v0.16.0 / 2021-03-17

* Initial release.
