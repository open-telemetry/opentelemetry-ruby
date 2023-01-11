###
# Benchmark the existing Ruby implementation
###

require "benchmark"
require "benchmark/memory"
require_relative "../../sdk/lib/opentelemetry-sdk"

ENV['OTEL_TRACES_EXPORTER'] = ''

n = 1_000_000
Benchmark.bmbm do |x|
  x.report("ruby-cpu") do
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
  x.report("ruby-memory") do
    OpenTelemetry::SDK.configure
    tp = OpenTelemetry::SDK::Trace::TracerProvider.new
    tracer = tp.tracer("benchmark", "0.1.0")

    n.times {
      span = tracer.start_span("foo", attributes: {"answer" => 42, "true" => true, "false" => false, "float" => 1.0, "stringy" => "mcstringface"})
      span.finish
    }
  end
end
