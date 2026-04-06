# Release History: opentelemetry-exporter-jaeger

### v0.24.1 / 2025-12-02

* FIXED: Update version compatibility: < Ruby 3.2, < JRuby 10.0

### v0.24.0 / 2025-02-25

- ADDED: Support 3.1 Min Version

### v0.23.0 / 2023-06-08

- BREAKING CHANGE: Remove support for EoL Ruby 2.7

- ADDED: Remove support for EoL Ruby 2.7

### v0.22.0 / 2022-09-14

- ADDED: Add dropped events/attributes/links counts to zipkin + jaeger exporters
- ADDED: Metrics reporter for Jaeger collector exporter
- ADDED: Support InstrumentationScope, and update OTLP proto to 0.18.0

### v0.21.0 / 2022-06-09

- (No significant changes)

### v0.20.2 / 2022-05-02

- DOCS: Fix exporter port in Jaeger exporter readme

### v0.20.1 / 2021-09-29

- (No significant changes)

### v0.20.0 / 2021-08-12

- ADDED: OTEL_EXPORTER_JAEGER_TIMEOUT env var
- DOCS: Update docs to rely more on environment variable configuration

### v0.19.0 / 2021-06-23

- BREAKING CHANGE: Total order constraint on span.status=

- FIXED: Total order constraint on span.status=

### v0.18.0 / 2021-05-21

- BREAKING CHANGE: Replace Time.now with Process.clock_gettime

- ADDED: Export to jaeger collectors w/ self-signed certs
- FIXED: Replace Time.now with Process.clock_gettime
- FIXED: Rename constant to hide warning message
- FIXED: Index a link trace_id in middle rather than end

### v0.17.0 / 2021-04-22

- ADDED: Add zipkin exporter

### v0.16.0 / 2021-03-17

- BREAKING CHANGE: Implement Exporter#force_flush

- ADDED: Implement Exporter#force_flush
- DOCS: Replace Gitter with GitHub Discussions

### v0.15.0 / 2021-02-18

- BREAKING CHANGE: Streamline processor pipeline

- FIXED: Streamline processor pipeline

### v0.14.0 / 2021-02-03

- (No significant changes)

### v0.13.0 / 2021-01-29

- ADDED: Provide default resource in SDK
- ADDED: Add untraced wrapper to common utils
- FIXED: Jaeger ref type should be FOLLOWS_FROM

### v0.12.0 / 2020-12-24

- ADDED: Structured error handling

### v0.11.0 / 2020-12-11

- FIXED: Copyright comments to not reference year

### v0.10.0 / 2020-12-03

- (No significant changes)

### v0.9.0 / 2020-11-27

- BREAKING CHANGE: Add timeout for force_flush and shutdown

- ADDED: Add timeout for force_flush and shutdown

### v0.8.0 / 2020-10-27

- BREAKING CHANGE: Move context/span methods to Trace module
- BREAKING CHANGE: Remove 'canonical' from status codes
- BREAKING CHANGE: Assorted SpanContext fixes

- FIXED: Move context/span methods to Trace module
- FIXED: Remove 'canonical' from status codes
- FIXED: Assorted SpanContext fixes

### v0.7.0 / 2020-10-07

- ADDED: Add service_version setter to configurator
- FIXED: Update IL attribute naming convention to match spec
- DOCS: Standardize top-level docs structure and readme
- DOCS: Use BatchSpanProcessor in examples

### v0.6.0 / 2020-09-10

- This gem was renamed from `opentelemetry-exporters-jaeger`.
