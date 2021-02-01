# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::Trace::Propagation::TraceContext do
  describe '#text_map_extractor' do
    it 'returns an instance of TextMapExtractor' do
      extractor = OpenTelemetry::Trace::Propagation::TraceContext.text_map_extractor
      _(extractor).must_be_instance_of(
        OpenTelemetry::Trace::Propagation::TraceContext::TextMapExtractor
      )
    end
  end

  describe '#text_map_injector, #rack_injector' do
    it 'returns an instance of TextMapInjector' do
      injector = OpenTelemetry::Trace::Propagation::TraceContext.text_map_injector
      _(injector).must_be_instance_of(
        OpenTelemetry::Trace::Propagation::TraceContext::TextMapInjector
      )
    end
  end
end
