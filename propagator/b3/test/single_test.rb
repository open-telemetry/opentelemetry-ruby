# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::Propagator::B3::Single do
  describe '#text_map_extractor' do
    it 'returns an instance of TextMapExtractor' do
      extractor = OpenTelemetry::Propagator::B3::Single.text_map_extractor
      _(extractor).must_be_instance_of(
        OpenTelemetry::Propagator::B3::Single::TextMapExtractor
      )
    end
  end

  describe '#text_map_injector, #rack_injector' do
    it 'returns an instance of TextMapInjector' do
      injector = OpenTelemetry::Propagator::B3::Single.text_map_injector
      _(injector).must_be_instance_of(
        OpenTelemetry::Propagator::B3::Single::TextMapInjector
      )
    end
  end
end
