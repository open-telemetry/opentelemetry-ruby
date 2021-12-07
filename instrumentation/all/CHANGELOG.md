# Release History: opentelemetry-instrumentation-all

### v0.22.0 / 2021-12-01

* ADDED: Move activesupport notification subsciber out of action_view gem 

### v0.21.3 / 2021-10-07

* (No significant changes)

### v0.21.2 / 2021-09-29

* (No significant changes)

### v0.21.1 / 2021-09-29

* (No significant changes)

### v0.21.0 / 2021-09-15

* ADDED: Add Que instrumentation 

### v0.20.2 / 2021-09-09

* (No significant changes)

### v0.20.1 / 2021-08-18

* FIXED: Instrumentation all sidekiq 

### v0.20.0 / 2021-08-12

* ADDED: Instrument active record 
* ADDED: Add ActionView instrumentation via ActiveSupport::Notifications 

### v0.19.0 / 2021-06-25

* ADDED: Add resque instrumentation
* ADDED: Add ActiveJob instrumentation
* ADDED: Configuration option to enable or disable redis root spans [#777](https://github.com/open-telemetry/opentelemetry-ruby/pull/777)
* FIXED: Broken instrumentation all release 

### v0.18.0 / 2021-05-21

* ADDED: Add koala instrumentation

### v0.17.0 / 2021-04-22

* ADDED: Add instrumentation for postgresql (pg gem)

### v0.16.0 / 2021-03-17

* ADDED: Instrument http gem
* ADDED: Instrument lmdb gem
* FIXED: Example scripts now reference local common lib
* DOCS: Replace Gitter with GitHub Discussions

### v0.15.0 / 2021-02-18

* ADDED: Instrument http client gem

### v0.14.0 / 2021-02-03

* (No significant changes)

### v0.13.0 / 2021-01-29

* (No significant changes)

### v0.12.1 / 2021-01-13

* ADDED: Instrument RubyKafka

### v0.12.0 / 2020-12-24

* ADDED: Instrument graphql

### v0.11.0 / 2020-12-11

* FIXED: Copyright comments to not reference year

### v0.10.0 / 2020-12-03

* FIXED: Otel-instrumentation-all not installing all

### v0.9.0 / 2020-11-27

* ADDED: Add common helpers

### v0.8.0 / 2020-10-27

* (No significant changes)

### v0.7.0 / 2020-10-07

* DOCS: Standardize toplevel docs structure and readme

### v0.6.0 / 2020-09-10

* Now depends on version 0.6.x of all the individual instrumentation gems.
