# frozen_string_literal: true

require "test/unit"
require_relative "../lib/opentelemetry_sdk_rust"

class SDKTest < Test::Unit::TestCase
  def test_tracer_provider
    assert { !OpenTelemetry::SDK::Trace::TracerProvider.new.nil? }
    assert { !OpenTelemetry::SDK::Trace::TracerProvider.new.tracer("foo").nil? }
    assert { !OpenTelemetry::SDK::Trace::TracerProvider.new.tracer("foo", "1.2.3").nil? }
    assert_nothing_raised { OpenTelemetry::SDK::Trace::TracerProvider.new.tracer("foo", "1.2.3").start_span("bar").finish }
  end

  def test_sdk_configure
    assert_nothing_raised do
      OpenTelemetry::SDK.configure
      tp = OpenTelemetry::SDK::Trace::TracerProvider.new
      tp.tracer("foo", "1.2.3").start_span("bar", attributes: {"answer" => 42, "true" => true, "false" => false, "float" => 1.0, "stringy" => "mcstringface"}).finish
      tp.shutdown
    end
  end

  def test_sdk_configure_with_env
    assert_nothing_raised do
      ENV['OTEL_EXPORTER_OTLP_ENDPOINT'] = 'http://localhost:4317'
      ENV['OTEL_TRACES_EXPORTER'] = 'otlp'

      rt = Tokio::Runtime.new

      rt.enter do
        OpenTelemetry::SDK.configure
      end

      tp = OpenTelemetry::SDK::Trace::TracerProvider.new
      tp.tracer("foo", "1.2.3").start_span("bar", attributes: {"answer" => 42, "true" => true, "false" => false, "float" => 1.0, "stringy" => "mcstringface"}).finish

      tp.shutdown # on the Rust side, drops the inner TracerProvider held in global
      ENV.delete('OTEL_EXPORTER_OTLP_ENDPOINT')
      ENV.delete('OTEL_TRACES_EXPORTER')
    end
  end
end
