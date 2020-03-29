# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::CorrelationContext::Propagation do
  describe '#http_extractor, #rack_http_extractor' do
    it 'returns an instance of HttpExtractor' do
      %i[http_extractor rack_http_extractor].each do |extractor_method|
        extractor = OpenTelemetry::CorrelationContext::Propagation.send(extractor_method)
        _(extractor).must_be_instance_of(
          OpenTelemetry::CorrelationContext::Propagation::HttpExtractor
        )
      end
    end
  end

  describe '#http_injector, #rack_http_injector' do
    it 'returns an instance of HttpInjector' do
      %i[http_injector rack_http_injector].each do |injector_method|
        injector = OpenTelemetry::CorrelationContext::Propagation.send(injector_method)
        _(injector).must_be_instance_of(
          OpenTelemetry::CorrelationContext::Propagation::HttpInjector
        )
      end
    end
  end
end
