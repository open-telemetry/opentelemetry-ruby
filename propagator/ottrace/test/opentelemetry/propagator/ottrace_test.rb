# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::Propagator::OTTrace do
  describe '#text_map_extractor' do
    it 'returns an instance of TextMapExtractor' do
      extractor = OpenTelemetry::Propagator::OTTrace.text_map_extractor
      _(extractor).must_be_instance_of(
        OpenTelemetry::Propagator::OTTrace::TextMapExtractor
      )
    end
  end

  describe '#text_map_injector' do
    it 'returns an instance of TextMapInjector' do
      extractor = OpenTelemetry::Propagator::OTTrace.text_map_injector
      _(extractor).must_be_instance_of(
        OpenTelemetry::Propagator::OTTrace::TextMapInjector
      )
    end
  end
end
