# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::Metrics::Instrument::Histogram do
  describe '#record' do
    it 'responds without errors and returns nil' do
      histogram = build_histogram('test-instrument')

      assert(histogram.record(1).nil?)
      assert(histogram.record(1, attributes: nil).nil?)
      assert(histogram.record(1, attributes: {}).nil?)
      assert(histogram.record(1, attributes: { 'key' => 'value' }).nil?)
    end
  end

  def build_histogram(*args, **kwargs)
    OpenTelemetry::Metrics::Instrument::Histogram.new(*args, **kwargs)
  end
end
