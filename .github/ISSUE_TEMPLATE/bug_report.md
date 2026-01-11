---
name: Bug report
about: Notify us of an error or incorrect behavior
title: ''
labels: 'bug'
assignees: ''

---

<!--

NOTE: Please use this form to submit bugs or demonstrations of non spec compliant behavior

-->

**Description of the bug**

<!--

If this for behavior that is not compliant with the OpenTelemetry Specification, please describe
what happened and what you expected with a link to the relevant portion of the spec.

-->

**Share details about your runtime**

Operating system details: Linux, Ubuntu 20.04 LTS
RUBY_ENGINE: "ruby"
RUBY_VERSION: "3.1.1"
RUBY_DESCRIPTION: "ruby 3.1.1p18 (2022-02-18 revision 53f5fc4236) [arm64-darwin21]"

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

<sub>**Tip**: [React](https://github.blog/news-insights/product-news/add-reactions-to-pull-requests-issues-and-comments/) with 👍 to help prioritize this issue. Please use comments to provide useful context, avoiding `+1` or `me too`, to help us triage it. Learn more [here](https://opentelemetry.io/community/end-user/issue-participation/).</sub>
