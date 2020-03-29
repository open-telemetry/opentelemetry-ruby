# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::Trace::Propagation::TraceContext do
  describe '#text_extractor, #rack_extractor' do
    it 'returns an instance of TextExtractor' do
      %i[text_extractor rack_extractor].each do |extractor_method|
        extractor = OpenTelemetry::Trace::Propagation::TraceContext.send(extractor_method)
        _(extractor).must_be_instance_of(
          OpenTelemetry::Trace::Propagation::TraceContext::TextExtractor
        )
      end
    end
  end

  describe '#text_injector, #rack_injector' do
    it 'returns an instance of TextInjector' do
      %i[text_injector rack_injector].each do |injector_method|
        injector = OpenTelemetry::Trace::Propagation::TraceContext.send(injector_method)
        _(injector).must_be_instance_of(
          OpenTelemetry::Trace::Propagation::TraceContext::TextInjector
        )
      end
    end
  end
end
