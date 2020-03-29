# frozen_string_literal: true

# Copyright 2020 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::Context::Propagation::NoopExtractor do
  describe '#extractor' do
    it 'returns the original context' do
      context = OpenTelemetry::Context.empty.set_value('k1', 'v1')
      extractor = OpenTelemetry::Context::Propagation::NoopExtractor.new
      result = extractor.extract({ 'foo' => 'bar' }, context)
      _(result).must_equal(context)
    end
  end
end
