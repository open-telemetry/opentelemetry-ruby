require "benchmark"
require "benchmark/memory"

ENV['OTEL_TRACES_EXPORTER'] = ''

n = 1_000_000
Benchmark.bmbm do |x|
  x.report("rust-cpu") do
    require_relative "../lib/opentelemetry_sdk_rust"
    OpenTelemetry::SDK.configure
    tp = OpenTelemetry::SDK::Trace::TracerProvider.new
    tracer = tp.tracer("benchmark", "0.1.0")

    n.times {
      span = tracer.start_span("foo", attributes: {"answer" => 42, "true" => true, "false" => false, "float" => 1.0, "stringy" => "mcstringface"})
      span.finish
    }
    GC.start
  end

  x.report("ruby-cpu") do
    require "opentelemetry/sdk"
    OpenTelemetry::SDK.configure
    tp = OpenTelemetry::SDK::Trace::TracerProvider.new
    tracer = tp.tracer("benchmark", "0.1.0")

    n.times {
      span = tracer.start_span("foo", attributes: {"answer" => 42, "true" => true, "false" => false, "float" => 1.0, "stringy" => "mcstringface"})
      span.finish
    }
    GC.start
  end
end

n = 1_000
Benchmark.memory do |x|
  x.report("rust-memory") do
    require_relative "../lib/opentelemetry_sdk_rust"
    OpenTelemetry::SDK.configure
    tp = OpenTelemetry::SDK::Trace::TracerProvider.new
    tracer = tp.tracer("benchmark", "0.1.0")

    n.times {
      span = tracer.start_span("foo", attributes: {"answer" => 42, "true" => true, "false" => false, "float" => 1.0, "stringy" => "mcstringface"})
      span.finish
    }
    GC.start
  end

  x.report("ruby-memory") do
    require "opentelemetry/sdk"
    OpenTelemetry::SDK.configure
    tp = OpenTelemetry::SDK::Trace::TracerProvider.new
    tracer = tp.tracer("benchmark", "0.1.0")

    n.times {
      span = tracer.start_span("foo", attributes: {"answer" => 42, "true" => true, "false" => false, "float" => 1.0, "stringy" => "mcstringface"})
      span.finish
    }
    GC.start
  end

  x.compare!
end
