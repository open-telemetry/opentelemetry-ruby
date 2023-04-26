# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::Metrics::Instrument::UpDownCounter do
  describe '#add' do
    it 'responds without errors and returns nil' do
      up_down_counter = build_up_down_counter('test-instrument')

      assert(up_down_counter.add(1).nil?)
      assert(up_down_counter.add(1, attributes: nil).nil?)
      assert(up_down_counter.add(1, attributes: {}).nil?)
      assert(up_down_counter.add(1, attributes: { 'key' => 'value' }).nil?)
    end
  end

  def build_up_down_counter(*args, **kwargs)
    OpenTelemetry::Metrics::Instrument::UpDownCounter.new(*args, **kwargs)
  end
end
