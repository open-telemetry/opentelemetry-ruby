# frozen_string_literal: true

# Copyright 2020 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

require_relative '../../../lib/opentelemetry/instrumentation/rack'

describe OpenTelemetry::Instrumentation::Rack do
  let(:instrumentation) { OpenTelemetry::Instrumentation::Rack::Instrumentation.instance }

  it 'has #name' do
    _(instrumentation.name).must_equal 'OpenTelemetry::Instrumentation::Rack'
  end

  it 'has #version' do
    _(instrumentation.version).wont_be_nil
    _(instrumentation.version).wont_be_empty
  end

  describe '#install' do
    it 'accepts argument' do
      instrumentation.install({})
    end
  end

  describe '#current_span' do
    it 'returns Span::INVALID when there is none set' do
      _(OpenTelemetry::Instrumentation::Rack.current_span).must_equal(OpenTelemetry::Trace::Span::INVALID)
    end

    it 'returns the span when set' do
      test_span = OpenTelemetry::Trace::Span.new
      context = OpenTelemetry::Instrumentation::Rack.context_with_span(test_span)
      _(OpenTelemetry::Instrumentation::Rack.current_span(context)).must_equal(test_span)
    end
  end

  describe '#with_span' do
    it 'respects context nesting' do
      test_span = OpenTelemetry::Trace::Span.new
      test_span2 = OpenTelemetry::Trace::Span.new
      OpenTelemetry::Instrumentation::Rack.with_span(test_span) do
        _(OpenTelemetry::Instrumentation::Rack.current_span).must_equal(test_span)

        OpenTelemetry::Instrumentation::Rack.with_span(test_span2) do
          _(OpenTelemetry::Instrumentation::Rack.current_span).must_equal(test_span2)
        end

        _(OpenTelemetry::Instrumentation::Rack.current_span).must_equal(test_span)
      end
    end
  end
end
