# frozen_string_literal: true

# Copyright 2020 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::Propagator::XRay do
  describe '#text_map_extractor, #rack_extractor' do
    it 'returns an instance of TextMapExtractor' do
      %i[text_map_extractor rack_extractor].each do |extractor_method|
        extractor = OpenTelemetry::Propagator::XRay.send(extractor_method)
        _(extractor).must_be_instance_of(
          OpenTelemetry::Propagator::XRay::TextMapExtractor
        )
      end
    end
  end

  describe '#text_map_injector, #rack_injector' do
    it 'returns an instance of TextMapInjector' do
      %i[text_map_injector rack_injector].each do |injector_method|
        injector = OpenTelemetry::Propagator::XRay.send(injector_method)
        _(injector).must_be_instance_of(
          OpenTelemetry::Propagator::XRay::TextMapInjector
        )
      end
    end
  end
end
