# Release History: opentelemetry-instrumentation-sidekiq

### v0.20.2 / 2021-12-02

* (No significant changes)

### v0.20.1 / 2021-09-29

* (No significant changes)

### v0.20.0 / 2021-08-18

* ADDED: Gracefully flush provider on sidekiq shutdown event 

### v0.19.1 / 2021-08-12

* (No significant changes)

### v0.19.0 / 2021-06-23

* BREAKING CHANGE: Sidekiq propagation config 
  - Config option enable_job_class_span_names renamed to span_naming and now expects a symbol of value :job_class, or :queue
  - The default behaviour is no longer to have one continuous trace for the enqueue and process spans, using links is the new default.  To maintain the previous behaviour the config option propagation_style must be set to :child.
* BREAKING CHANGE: Total order constraint on span.status= 

* FIXED: Sidekiq propagation config 
* FIXED: Total order constraint on span.status= 

### v0.18.0 / 2021-05-21

* ADDED: Updated API depedency for 1.0.0.rc1
* TEST: update test for redis instrumentation refactor [#760](https://github.com/open-telemetry/opentelemetry-ruby/pull/760)
* BREAKING CHANGE: Remove optional parent_context from in_span

* FIXED: Remove optional parent_context from in_span
* FIXED: Instrument Redis more thoroughly by patching Client#process.

### v0.17.0 / 2021-04-22

* ADDED: Accept config for sidekiq peer service attribute

### v0.16.0 / 2021-03-17

* FIXED: Example scripts now reference local common lib
* DOCS: Replace Gitter with GitHub Discussions

### v0.15.0 / 2021-02-18

* ADDED: Add instrumentation config validation

### v0.14.0 / 2021-02-03

* BREAKING CHANGE: Replace getter and setter callables and remove rack specific propagators

* ADDED: Replace getter and setter callables and remove rack specific propagators

### v0.13.0 / 2021-01-29

* ADDED: Instrument sidekiq background work
* FIXED: Adjust Sidekiq middlewares to match semantic conventions
* FIXED: Set minimum compatible version and use untraced helper

### v0.12.0 / 2020-12-24

* (No significant changes)

### v0.11.0 / 2020-12-11

* FIXED: Copyright comments to not reference year

### v0.10.0 / 2020-12-03

* (No significant changes)

### v0.9.0 / 2020-11-27

* BREAKING CHANGE: Add timeout for force_flush and shutdown

* ADDED: Add timeout for force_flush and shutdown

### v0.8.0 / 2020-10-27

* (No significant changes)

### v0.7.0 / 2020-10-07

* DOCS: Adding README for Sidekiq instrumentation
* DOCS: Remove duplicate reference in Sidekiq README
* DOCS: Standardize toplevel docs structure and readme

### v0.6.0 / 2020-09-10

* (No significant changes)
