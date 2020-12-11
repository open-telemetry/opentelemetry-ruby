# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::Baggage::Propagation do
  describe '#text_map_extractor, #rack_extractor' do
    it 'returns an instance of TextMapExtractor' do
      %i[text_map_extractor rack_extractor].each do |extractor_method|
        extractor = OpenTelemetry::Baggage::Propagation.send(extractor_method)
        _(extractor).must_be_instance_of(
          OpenTelemetry::Baggage::Propagation::TextMapExtractor
        )
      end
    end
  end

  describe '#text_map_injector, #rack_injector' do
    it 'returns an instance of TextMapInjector' do
      %i[text_map_injector rack_injector].each do |injector_method|
        injector = OpenTelemetry::Baggage::Propagation.send(injector_method)
        _(injector).must_be_instance_of(
          OpenTelemetry::Baggage::Propagation::TextMapInjector
        )
      end
    end
  end
end
