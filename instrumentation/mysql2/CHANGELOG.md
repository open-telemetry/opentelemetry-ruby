# Release History: opentelemetry-instrumentation-mysql2

### Unreleased

* ADDED: `with_attributes` method for context propagation

### v0.20.0 / 2021-12-01

* ADDED: Add default options config helper + env var config option support 

### v0.19.1 / 2021-09-29

* (No significant changes)

### v0.19.0 / 2021-08-12

* BREAKING CHANGE: Add option for db.statement 

* ADDED: Add option for db.statement 
* DOCS: Update docs to rely more on environment variable configuration 
* DOCS: Move to using new db_statement 

### v0.18.1 / 2021-06-23

* (No significant changes)

### v0.18.0 / 2021-05-21

* ADDED: Updated API depedency for 1.0.0.rc1
* Fix: Nil value for db.name attribute #744

### v0.17.0 / 2021-04-22

* (No significant changes)

### v0.16.0 / 2021-03-17

* FIXED: Update DB semantic conventions
* FIXED: Example scripts now reference local common lib
* ADDED: Configurable obfuscation of sql in mysql2 instrumentation to avoid logging sensitive data

### v0.15.0 / 2021-02-18

* ADDED: Add instrumentation config validation

### v0.14.0 / 2021-02-03

* (No significant changes)

### v0.13.0 / 2021-01-29

* (No significant changes)

### v0.12.0 / 2020-12-24

* (No significant changes)

### v0.11.0 / 2020-12-11

* ADDED: Add peer service config to mysql
* FIXED: Copyright comments to not reference year

### v0.10.1 / 2020-12-09

* FIXED: Semantic conventions db.type -> db.system

### v0.10.0 / 2020-12-03

* (No significant changes)

### v0.9.0 / 2020-11-27

* BREAKING CHANGE: Add timeout for force_flush and shutdown

* ADDED: Add timeout for force_flush and shutdown

### v0.8.0 / 2020-10-27

* BREAKING CHANGE: Remove 'canonical' from status codes

* FIXED: Remove 'canonical' from status codes

### v0.7.0 / 2020-10-07

* DOCS: Standardize toplevel docs structure and readme

### v0.6.0 / 2020-09-10

* (No significant changes)
