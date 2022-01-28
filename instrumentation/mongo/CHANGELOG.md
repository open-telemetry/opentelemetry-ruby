# Release History: opentelemetry-instrumentation-mongo

### v0.18.4 / 2021-12-02

* (No significant changes)

### v0.18.3 / 2021-09-29

* (No significant changes)

### v0.18.2 / 2021-08-12

* FIXED: Flakey mongo test 

### v0.18.1 / 2021-06-23

* (No significant changes)

### v0.18.0 / 2021-05-21

* BREAKING CHANGE: Replace Time.now with Process.clock_gettime

* ADDED: Updated API depedency for 1.0.0.rc1
* FIXED: Replace Time.now with Process.clock_gettime
* FIXED: Mongodb test asserting error message

### v0.17.0 / 2021-04-22

* ADDED: Mongo instrumentation accepts peer service config attribute.
* FIXED: Fix Mongo instrumentation example.
* FIXED: Refactor propagators to add #fields

### v0.16.0 / 2021-03-17

* FIXED: Example scripts now reference local common lib
* DOCS: Replace Gitter with GitHub Discussions

### v0.15.0 / 2021-02-18

* (No significant changes)

### v0.14.0 / 2021-02-03

* BREAKING CHANGE: Replace getter and setter callables and remove rack specific propagators

* ADDED: Replace getter and setter callables and remove rack specific propagators

### v0.13.0 / 2021-01-29

* FIXED: Mongo Instrumenter: Do not send nil attributes

### v0.12.0 / 2020-12-24

* (No significant changes)

### v0.11.0 / 2020-12-11

* FIXED: Copyright comments to not reference year

### v0.10.0 / 2020-12-03

* (No significant changes)

### v0.9.0 / 2020-11-03

* Initial release of Mongo instrumenter (ported from Datadog)
