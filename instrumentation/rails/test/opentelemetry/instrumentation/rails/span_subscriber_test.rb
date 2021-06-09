# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::Instrumentation::Rails::SpanSubscriber do
  let(:tracer) { OpenTelemetry::Instrumentation::Rails::Instrumentation.instance.tracer }
  let(:exporter) { EXPORTER }
  let(:last_span) { exporter.finished_spans.last }
  let(:subscriber) do
    OpenTelemetry::Instrumentation::Rails::SpanSubscriber.new(
      name: "bar.foo",
      tracer: tracer
    )
  end

  before { exporter.reset }

  it "memoizes the span name" do
    span, _ = subscriber.start("oh.hai", "abc", {})
    _(span.name).must_equal("foo bar")
  end

  it "uses the provided tracer" do
    subscriber = OpenTelemetry::Instrumentation::Rails::SpanSubscriber.new(
      name: "oh.hai",
      tracer: OpenTelemetry.tracer_provider.tracer("foo"),
    )
    span, _ = subscriber.start("oh.hai", "abc", {})
    _(span.instrumentation_library.name).must_equal("foo")
  end

  it "finishes the passed span" do
    span, prev_ctx = subscriber.start("hai", "abc", {})
    subscriber.finish("hai", "abc", {
      __opentelemetry_span: span,
      __opentelemetry_prev_ctx: prev_ctx
    })

    # If it's in exporter.finished_spans ... it's finished.
    _(last_span).wont_be_nil
  end

  it "sets attributes as expected" do
    span, prev_ctx = subscriber.start("hai", "abc", {})
    # We only use the finished attributes - could change in the
    # future, perhaps.
    subscriber.finish("hai", "abc", {
      __opentelemetry_span: span,
      __opentelemetry_prev_ctx: prev_ctx,
      simple: "keys_are_present",
      exception: "is_not_set_as_attribute",
      nil_values_are_rejected: nil
    })

    _(last_span).wont_be_nil
    _(last_span.attributes["simple"]).must_equal("keys_are_present")
    _(last_span.attributes.key?("exception")).must_equal(false)
    _(last_span.attributes.key?("nil_values_are_rejected")).must_equal(false)
  end

  it "logs an exception_object correctly" do
    span, prev_ctx = subscriber.start("hai", "abc", {})
    # We only use the finished attributes - could change in the
    # future, perhaps.
    subscriber.finish("hai", "abc", {
      __opentelemetry_span: span,
      __opentelemetry_prev_ctx: prev_ctx,
      exception_object: Exception.new("boom"),
    })

    status = last_span.status
    _(status.code).must_equal(OpenTelemetry::Trace::Status::ERROR)
    _(status.description).must_equal("Unhandled exception of type: Exception")

    event = last_span.events.first
    _(event.name).must_equal("exception")
    _(event.attributes["exception.message"]).must_equal("boom")
  end
end
