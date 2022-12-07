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
      tp.tracer("foo", "1.2.3").start_span("bar").finish
      tp.shutdown
    end
  end
end
