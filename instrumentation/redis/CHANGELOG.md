# Release History: opentelemetry-instrumentation-redis

### v0.21.2 / 2021-12-01

* (No significant changes)

### v0.21.1 / 2021-09-29

* (No significant changes)

### v0.21.0 / 2021-08-12

* ADDED: Add toggle for redis db.statement attribute 

### v0.20.0 / 2021-06-23

* BREAKING CHANGE: Total order constraint on span.status= 

* FIXED: Total order constraint on span.status= 

### v0.19.0 / 2021-05-28

* ADDED: Configuration option to enable or disable redis root spans [#777](https://github.com/open-telemetry/opentelemetry-ruby/pull/777)

### v0.18.0 / 2021-05-21

* ADDED: Updated API depedency for 1.0.0.rc1
refactor: redis attribute utils [#760](https://github.com/open-telemetry/opentelemetry-ruby/pull/760)
refactor: simplify redis attribute assignment [#758](https://github.com/open-telemetry/opentelemetry-ruby/pull/758)
test: split redis instrumentation test [#754](https://github.com/open-telemetry/opentelemetry-ruby/pull/754)
* ADDED: Option to obfuscate redis arguments
* FIXED: Instrument Redis more thoroughly by patching Client#process.

### v0.17.0 / 2021-04-22

* (No significant changes)

### v0.16.0 / 2021-03-17

* FIXED: Update DB semantic conventions
* FIXED: Example scripts now reference local common lib
* DOCS: Replace Gitter with GitHub Discussions

### v0.15.0 / 2021-02-18

* ADDED: Add instrumentation config validation

### v0.14.0 / 2021-02-03

* (No significant changes)

### v0.13.0 / 2021-01-29

* (No significant changes)

### v0.12.0 / 2020-12-24

* (No significant changes)

### v0.11.0 / 2020-12-11

* ADDED: Accept config for redis peer service attribute
* ADDED: Move utf8 encoding to common utils
* FIXED: Copyright comments to not reference year

### v0.10.1 / 2020-12-09

* FIXED: Semantic conventions db.type -> db.system

### v0.10.0 / 2020-12-03

* (No significant changes)

### v0.9.0 / 2020-11-27

* BREAKING CHANGE: Add timeout for force_flush and shutdown

* ADDED: Redis attribute propagation
* ADDED: Add timeout for force_flush and shutdown

### v0.8.0 / 2020-10-27

* BREAKING CHANGE: Remove 'canonical' from status codes

* FIXED: Remove 'canonical' from status codes

### v0.7.0 / 2020-10-07

* DOCS: Added redis documentation
* DOCS: Standardize toplevel docs structure and readme

### v0.6.0 / 2020-09-10

* (No significant changes)
