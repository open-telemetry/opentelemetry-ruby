---
name: Bug report
about: Notify us of an error or incorrect behaviour
title: ''
labels: 'bug'
assignees: ''

---

<!--

NOTE: Please use this form to submit bugs or demonstrations of non spec compliant behaviour

-->

**Description of the bug**

<!--

If this for behaviour that is not compliant with the OpenTelemetry Specification, please describe
what happened and what you expected with a link to the relevant portion of the spec.

-->

**Share details about your runtime**

Operating system details: Linux, Ubuntu 20.04 LTS
RUBY_ENGINE: "ruby"
RUBY_VERSION: "2.5.3"
RUBY_DESCRIPTION: "ruby 2.5.3p105 (2018-10-18 revision 65156) [x86_64-darwin19]"

**Share a simplified reproduction if possible**

```rb
require 'bundler/inline'

gemfile(true) do
  source 'https://rubygems.org'

  gem 'opentelemetry-api'
  gem 'opentelemetry-sdk'
  # gem 'opentelemetry-exporter-jaeger'
  # gem 'opentelemetry-exporter-otlp'
  # gem 'opentelemetry-exporter-zipkin'
end

require 'opentelemetry-api'
require 'opentelemetry-sdk'

span_processor = OpenTelemetry::SDK::Trace::Export::SimpleSpanProcessor.new(
  OpenTelemetry::SDK::Trace::Export::ConsoleSpanExporter.new
)

# require 'opentelemetry/exporter/jaeger'
# exporter = OpenTelemetry::Exporter::Jaeger::AgentExporter.new(max_packet_size: 9 * 1024)
# span_processor = OpenTelemetry::SDK::Trace::Export::BatchSpanProcessor.new(exporter)

# require 'opentelemetry/shopify/exporters/otlp'
# exporter = OpenTelemetry::Exporter::OTLP::Exporter.new
# span_processor = OpenTelemetry::SDK::Trace::Export::BatchSpanProcessor.new(exporter)

# require 'opentelemetry/shopify/exporters/otlp'
# exporter = OpenTelemetry::Exporter::OTLP::Exporter.new
# span_processor = OpenTelemetry::SDK::Trace::Export::BatchSpanProcessor.new(exporter)

OpenTelemetry::SDK.configure do |c|
  c.add_span_processor(span_processor)
end

SimpleTracer = OpenTelemetry.tracer_provider.tracer('Bug Report')

SimpleTracer.in_span('Parent span') do
  1..10.times { SimpleTracer.in_span('child span') {} }
end

OpenTelemetry.tracer_provider.shutdown
```
