# Release History: opentelemetry-propagator-jaeger

### v0.25.0 / 2026-05-12

* ADDED: Add git tag to source URI in gemspec (#2101)

### v0.24.0 / 2026-04-07

* ADDED: Min Ruby Version 3.3 (#2070)

### v0.23.0 / 2026-03-10

* ADDED: Replace cgi with uri for encode and decode (#2028)

### v0.22.0 / 2025-02-25

- ADDED: Support 3.1 Min Version

### v0.21.1 / 2024-02-06

- FIXED: Patch the issue for frozen string on ruby < 3.0 with string interpolation

### v0.21.0 / 2023-06-08

- BREAKING CHANGE: Remove support for EoL Ruby 2.7

- ADDED: Remove support for EoL Ruby 2.7

### v0.20.0 / 2022-06-09

- (No significant changes)

### v0.19.4 / 2022-05-02

- FIXED: Jaeger propagator doesn't handle missing trace id header

### v0.19.3 / 2021-12-01

- FIXED: Deprecate api rack env getter

### v0.19.2 / 2021-09-29

- (No significant changes)

### v0.19.1 / 2021-08-12

- (No significant changes)

### v0.19.0 / 2021-06-23

- BREAKING CHANGE: Refactor Baggage to remove Noop\*

- ADDED: Add Tracer.non_recording_span to API
- FIXED: Refactor Baggage to remove Noop\*

### v0.18.0 / 2021-05-21

- ADDED: Updated API dependency for 1.0.0.rc1

### v0.17.0 / 2021-04-22

- BREAKING CHANGE: Replace TextMapInjector/TextMapExtractor pairs with a TextMapPropagator.
- FIXED: Refactor propagators to add #fields

### v0.16.0 / 2021-03-17

- Initial release.
