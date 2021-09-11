---
title: "Ruby"
weight: 24
description: >
  <img width="35" src="https://raw.github.com/open-telemetry/opentelemetry.io/main/iconography/32x32/Ruby_SDK.svg"></img>
  A language-specific implementation of OpenTelemetry in Ruby.
---

This is the OpenTelemetry for Ruby documentation. OpenTelemetry is an observability framework -- an API, SDK, and tools that are designed to aid in the generation and collection of application telemetry data such as metrics, logs, and traces.
This documentation is designed to help you understand how to get started using OpenTelemetry for Ruby.

## Status and Releases

The current status of the major functional components for OpenTelemetry Ruby is
as follows:

| Tracing | Metrics | Logging |
| ------- | ------- | ------- |
| Release Candidate | Not Yet Implemented | Not Yet Implemented |

The current release can be found [here][releases]

## Using OpenTelemetry Ruby

- [Quick Start][quick-start]
- [Context Propagation][context-propagation]
- [Span Events][events]
- [Manual Instrumentation][manual-instrumentation]

## Further Reading

- [OpenTelemetry for Ruby on GitHub][repository]
- [Ruby API Documentation][ruby-docs]
- [Examples][examples]

[quick-start]: quick_start.md
[repository]: https://github.com/open-telemetry/opentelemetry-ruby
[releases]: https://github.com/open-telemetry/opentelemetry-ruby/releases
[auto-instrumenation]: https://github.com/open-telemetry/opentelemetry-ruby#instrumentation-libraries
[context-propagation]: context_propagation.md
[events]: events.md
[manual-instrumentation]: manual_instrumentation.md
[ruby-docs]: https://open-telemetry.github.io/opentelemetry-ruby/
[examples]: https://github.com/open-telemetry/opentelemetry-ruby/tree/main/examples
