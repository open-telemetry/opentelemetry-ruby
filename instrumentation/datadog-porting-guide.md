# Porting Guide

## Purpose

Aid developers who wish to port existing datadog (dd-trace-rb) instrumentation to opentelemetry.

## Interface

* There should be a subclass of `OpenTelemetry::Instrumentation::Base` that implements its DSL:
  * Implement `install` block, where all of the integration work happens
  * Implement `present` block
  * Optionally, implement `compatible`
  * See `OpenTelemetry::Instrumentation::Base` API documentation for more details

## Basic structure

* Add Gemfile, opentelemetry-instrumentation-#{name}.gemspec
* Add runnable (docker) example (using its own Gemfile)
```
$ docker-compose run ex-instrumentation-myinstrumentation bundle install
$ docker-compose run ex-instrumentation-myinstrumentation
bash-5.0$ ruby trace_demonstration.rb
```
* Rakefile
* `tests/test_helper.rb`
* Integrate rubocop (see https://github.com/open-telemetry/opentelemetry-ruby/pull/172#pullrequestreview-349183775)

## Examples and template instrumentation

* `instrumentation/faraday` and `instrumentation/sinatra` were the earliest, simplest implementations

## Implementation

* It's ok to use `require_relative` for files that are internal to the project
* Don't load integration implementation (require file) until `install` ('patch')-time
* Most times, only want to run installation (via `#install`) once, but need to
  consider being able to `reset` somehow for, e.g., testing

### otel: tracer

* `Tracer` `:name` and `:version` should come from instrumentation/base, not from the instrumented library

### otel: span

* Wrap instrumented-library operations in `span` (via `tracer.in_span` (block), or `tracer.start_span` (returns `Span`))
  * `Span.finish` should be called if using `tracer.start_span`
* Span `:with_parent` defaults to `current_span`

### otel: span.name (dd-trace-rb: 'resource')

* Prefer "low-cardinality" names (see https://github.com/open-telemetry/opentelemetry-specification/pull/416)

### otel: span.attributes (dd-trace-rb: 'tags')

* `Span` attribute keys should be strings, *not* symbols
* `Span` attribute values should be strings, *not* symbols
* Prefer to populate span attributes via method arguments (e.g., `tracer.in_span(attributes: ...`) instead of `span.set_attribute`
* Some `Span` attribute naming is based on [semantic conventions](https://github.com/open-telemetry/opentelemetry-specification/blob/master/specification/data-semantic-conventions.md), for example [HTTP semantic conventions](https://github.com/open-telemetry/opentelemetry-specification/blob/master/specification/data-http.md)
  * When opening a PR, it would be useful to note which attributes come from which semantic conventions, and which ones could not be found
* `Span` `:kind` defaults to `:internal` (other available options include `:client` or `:server`)

### Runnable example

* Gemfile should include "opentelemetry-instrumentation-#{instrumentation_name}"

### Runtime performance considerations

Watch for "low hanging fruit" performance improvements including:
* reduce object allocations - move to a constant, or cache values that would be generated repeatedly 
* look for "easy wins" vs. "complete redesigns"

## Testing

* Add tests via minitest (not rspec)
* Test against multiple versions of instrumented library via `appraisal`
  * GOTCHA: appraisal-2.2.0 + bundler-2.1.x (at least 2.1.4)
* Configure `.circleci/config.yml`
* Try to preserve all applicable tests from dd-trace-rb
  * Skip tests datadog-specific configurations
  * Skip tests for things that are not being ported

## Context propagation

* For client-only libraries, just `inject`
* For server-side libraries, `extract` remote span context from request headers, then start a new span using parent context (e.g., `tracer.in_span(with_parent_context: ...`)
* Use the plain `http_text_format` rather than `rack_http_text_format`

## Dependencies

* Allow instrumentation to function when underlying dependency (e.g., `faraday` gem) isn't present
  * Don't create a hard-dependency on instrumented libraries
* `opentelemetry-sdk` is only needed for tests

## Translation hints

* `span.set_tag` => `span.set_attribute`
* `Datadog::Logger.log.debug` => `OpenTelemetry.logger.debug`
* `span.resource` => ?? possibly `span.attributes[:url]`, etc., possibly ignored
* `span.service` => `span.name`
* `span.span_type` => `span.attributes[:component]`
* `options[:tracer]` => `OpenTelemetry.tracer_factory.tracer` (then, e.g., `Instrumentation.tracer`)

## Things to ignore (for now)

* Pin ('patch info') -- probably deprecated in dd-trace-rb
* Configuration option for `:distributed_tracing` (should always be enabled)
* Deprecation paths
* Passing spans/information around ENV
* `Span#set_error`
* `Contrib::Analytics`
* Quantization

## TBD (implementation differences)

* set a tag (attribute) value only once (check if set already)?
