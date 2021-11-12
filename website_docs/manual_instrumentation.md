---
title: "Manual Instrumentation"
weight: 4
---

Auto-instrumentation is the easiest way to get started with instrumenting your code, but in order to get the most insight into your system, you should add manual instrumentation where appropriate.
To do this, use the OpenTelemetry SDK to access the currently executing span and add attributes to it, and/or to create new spans.

### Adding Context to Exisiting Spans

It's often beneficial to add context to a currently executing span in a trace.
For example, you may have an application or service that handles extended warranties, and you want to associate it with the span when querying your tracing datastore.
In order to do this, get the current span from the context and set an attribute with your application's domain specific data:

```ruby
def track_extended_warranty(extended_warranty)
  current_span = OpenTelemetry::Trace.current_span
  current_span.add_attributes({
    "com.extended_warranty.id" => extended_warranty.id,
    "com.extended_warranty.timestamp" => extended_warranty.timestamp
  })
end
```

### Creating New Spans

Auto-instrumentation can show the shape of requests to your system, but only you know the really important parts.
In order to get the full picture of what's happening, you will have to add manual instrumentation and create some custom spans.
To do this, grab the tracer from the OpenTelemetry API and generate a span:

```ruby
# ...

def search_by(query)
  tracer = OpenTelemetry.tracer_provider.tracer('my-tracer')
  tracer.in_span("search_by") do |span|
    # ... expensive query
  end
end
```

The `in_span` convenience method is unique to Ruby implementation, which reduces some of the boilerplate code that you would have to otherwise write yourself:

```ruby
def search_by(query)
  span = tracer.start_span("search_by", kind: :internal)
  OpenTelemetry::Trace.with_span(span) do |span, context|
    # ... expensive query
  end
rescue Exception => e
  span&.record_exception(e)
  span&.status = OpenTelemetry::Trace::Status.error("Unhandled exception of type: #{e.class}")
  raise e
ensure
  span&.finish
end
```

### Attributes

Attributes are keys and values that are applied as metadata to your spans and are useful for aggregating, filtering, and grouping traces. Attributes can be added at span creation, or at any other time during the lifecycle of a span before it has completed.

```ruby
# setting attributes at creation...
tracer.in_span('foo', attributes: {  "hello" => "world", "some.number" => 1024, "tags" => [ "bugs", "won't fix" ] }, kind: :internal) do |span|

  # ... and after creation
  span.set_attribute("animals", ["elephant", "tiger"])

  span.add_attributes({ "my.cool.attribute" => "a value", "my.first.name" => "Oscar" })
end
```

> &#9888; Spans are thread safe data structures that require locks when they are mutated.
> You should therefore avoid calling `set_attribute` multiple times and instead assign attributes in bulk with a Hash, either during span creation or with `add_attributes` on an existing span.

#### Semantic Attributes

Semantic Attributes are attributes that are defined by the [OpenTelemetry Specification][] in order to provide a shared set of attribute keys across multiple languages, frameworks, and runtimes for common concepts like HTTP methods, status codes, user agents, and more. These attributes are available in the [Semantic Conventions gem][semconv-gem].

For details, see [Trace semantic conventions][semconv-spec].

[OpenTelemetry Specification]: {{< relref "/docs/reference/specification" >}}
[semconv-gem]: https://github.com/open-telemetry/opentelemetry-ruby/tree/main/semantic_conventions
[semconv-spec]: {{< relref "/docs/reference/specification/trace/semantic_conventions" >}}
