# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::Propagator::Jaeger do
  describe '#text_map_extractor' do
    it 'returns an instance of TextMapExtractor' do
      extractor = OpenTelemetry::Propagator::Jaeger.text_map_extractor
      _(extractor).must_be_instance_of(
        OpenTelemetry::Propagator::Jaeger::TextMapExtractor
      )
    end
  end

  describe '#text_map_injector' do
    it 'returns an instance of TextMapInjector' do
      injector = OpenTelemetry::Propagator::Jaeger.text_map_injector
      _(injector).must_be_instance_of(
        OpenTelemetry::Propagator::Jaeger::TextMapInjector
      )
    end
  end
end
