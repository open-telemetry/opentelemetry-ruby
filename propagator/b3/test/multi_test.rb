# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::Propagator::B3::Multi do
  describe '#text_map_extractor, #rack_extractor' do
    it 'returns an instance of TextMapExtractor' do
      %i[text_map_extractor rack_extractor].each do |extractor_method|
        extractor = OpenTelemetry::Propagator::B3::Multi.send(extractor_method)
        _(extractor).must_be_instance_of(
          OpenTelemetry::Propagator::B3::Multi::TextMapExtractor
        )
      end
    end
  end

  describe '#rack_injector, #rack_injector' do
    it 'returns an instance of TextMapInjector' do
      %i[rack_injector rack_injector].each do |injector_method|
        injector = OpenTelemetry::Propagator::B3::Multi.send(injector_method)
        _(injector).must_be_instance_of(
          OpenTelemetry::Propagator::B3::Multi::TextMapInjector
        )
      end
    end
  end
end
