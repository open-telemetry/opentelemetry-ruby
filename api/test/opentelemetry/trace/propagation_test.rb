# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::Trace::Propagation do
  describe '#http_trace_context_extractor, #rack_http_trace_context_extractor' do
    it 'returns an instance of HttpTraceContextExtractor' do
      %i[http_trace_context_extractor rack_http_trace_context_extractor].each do |extractor_method|
        extractor = OpenTelemetry::Trace::Propagation.send(extractor_method)
        _(extractor).must_be_instance_of(
          OpenTelemetry::Trace::Propagation::HttpTraceContextExtractor
        )
      end
    end
  end

  describe '#http_trace_context_injector, #rack_http_trace_context_injector' do
    it 'returns an instance of HttpTraceContextInjector' do
      %i[http_trace_context_injector rack_http_trace_context_injector].each do |injector_method|
        injector = OpenTelemetry::Trace::Propagation.send(injector_method)
        _(injector).must_be_instance_of(
          OpenTelemetry::Trace::Propagation::HttpTraceContextInjector
        )
      end
    end
  end
end
