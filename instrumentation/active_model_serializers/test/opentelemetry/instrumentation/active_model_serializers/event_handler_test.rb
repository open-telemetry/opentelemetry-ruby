# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require_relative '../../../test_helper'

# require Instrumentation so .install method is found:
require_relative '../../../../lib/opentelemetry/instrumentation/active_model_serializers'
require_relative '../../../../lib/opentelemetry/instrumentation/active_model_serializers/event_handler'

describe OpenTelemetry::Instrumentation::ActiveModelSerializers::EventHandler do
  let(:instrumentation) { OpenTelemetry::Instrumentation::ActiveModelSerializers::Instrumentation.instance }
  let(:exporter) { EXPORTER }
  let(:span) { exporter.finished_spans.first }
  let(:model) { TestHelper::Model.new(name: 'test object') }

  before do
    instrumentation.install
    exporter.reset

    # this is currently a noop but this will future proof the test
    @orig_propagation = OpenTelemetry.propagation
    propagator = OpenTelemetry::Trace::Propagation::TraceContext.text_map_propagator
    OpenTelemetry.propagation = propagator
  end

  after do
    OpenTelemetry.propagation = @orig_propagation
  end

  describe 'when adapter is set' do
    let(:render) { ActiveModelSerializers::SerializableResource.new(model).serializable_hash }

    it 'is expected to send a span' do
      _(exporter.finished_spans).must_equal []
      render
      _(exporter.finished_spans.size).must_equal 1

      _(span).must_be_kind_of OpenTelemetry::SDK::Trace::SpanData
      _(span.name).must_equal 'ModelSerializer render'
      _(span.attributes['serializer.name']).must_equal 'TestHelper::ModelSerializer'
      _(span.attributes['serializer.renderer']).must_equal 'active_model_serializers'
      _(span.attributes['serializer.format']).must_equal 'ActiveModelSerializers::Adapter::Attributes'
    end
  end

  describe 'when adapter is nil' do
    let(:render) { ActiveModelSerializers::SerializableResource.new(model, adapter: nil).serializable_hash }

    it 'is expected to send a span with adapter tag equal to the model name' do
      _(exporter.finished_spans).must_equal []
      render
      _(exporter.finished_spans.size).must_equal 1

      _(span).must_be_kind_of OpenTelemetry::SDK::Trace::SpanData
      _(span.name).must_equal 'ModelSerializer render'
      _(span.attributes['serializer.name']).must_equal 'TestHelper::ModelSerializer'
      _(span.attributes['serializer.renderer']).must_equal 'active_model_serializers'
      _(span.attributes['serializer.format']).must_equal 'TestHelper::Model'
    end
  end
end
