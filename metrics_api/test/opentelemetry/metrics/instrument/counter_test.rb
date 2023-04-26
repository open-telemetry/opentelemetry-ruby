# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::Metrics::Instrument::Counter do
  describe '#add' do
    it 'responds without errors and returns nil' do
      counter = build_counter('test-instrument')

      assert(counter.add(1).nil?)
      assert(counter.add(1, attributes: nil).nil?)
      assert(counter.add(1, attributes: {}).nil?)
      assert(counter.add(1, attributes: { 'key' => 'value' }).nil?)
    end
  end

  def build_counter(*args, **kwargs)
    OpenTelemetry::Metrics::Instrument::Counter.new(*args, **kwargs)
  end
end
