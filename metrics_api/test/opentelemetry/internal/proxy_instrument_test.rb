# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::Internal::ProxyInstrument do
  # Captures the arguments the proxy uses to recreate an instrument on a real meter.
  class RecordingMeter
    attr_reader :created

    def create_counter(name, unit: nil, description: nil, exemplar_filter: nil, exemplar_reservoir: nil)
      @created = { name: name, unit: unit, description: description }
    end

    def create_observable_counter(name, callback:, unit: nil, description: nil, exemplar_filter: nil, exemplar_reservoir: nil)
      @created = { name: name, unit: unit, description: description, callback: callback }
    end
  end

  describe '#upgrade_with' do
    it 'passes the callback to an upgraded asynchronous instrument' do
      callback = -> { 5 }
      instrument = build_proxy_instrument(:observable_counter, callback)
      meter = RecordingMeter.new

      instrument.upgrade_with(meter)

      _(meter.created[:callback]).must_equal(callback)
    end

    it 'passes the descriptor to an upgraded synchronous instrument' do
      instrument = build_proxy_instrument(:counter, nil)
      meter = RecordingMeter.new

      instrument.upgrade_with(meter)

      _(meter.created).must_equal(name: 'my.instrument', unit: 's', description: 'a description')
    end
  end

  def build_proxy_instrument(kind, callback)
    OpenTelemetry::Internal::ProxyInstrument.new(kind, 'my.instrument', 's', 'a description', callback, nil, nil)
  end
end
