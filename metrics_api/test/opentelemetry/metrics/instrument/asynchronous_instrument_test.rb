# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::Metrics::Instrument::AsynchronousInstrument do
  describe '#name' do
    it 'returns name' do
      instrument = build_asynchronous_instrument('test-instrument')

      assert(instrument.name == 'test-instrument')
    end
  end

  describe '#unit' do
    it 'returns unit' do
      instrument = build_asynchronous_instrument('test-instrument')
      assert(instrument.unit == '')

      instrument = build_asynchronous_instrument('test-instrument', unit: 'celsius')
      assert(instrument.unit == 'celsius')
    end
  end

  describe '#description' do
    it 'returns description' do
      instrument = build_asynchronous_instrument('test-instrument')
      assert(instrument.description == '')

      instrument = build_asynchronous_instrument('test-instrument', description: 'room temperature')
      assert(instrument.description == 'room temperature')
    end
  end

  describe '#callback' do
    it 'returns callback list' do
      instrument = build_asynchronous_instrument('test-instrument')
      assert(instrument.callback == [])

      callback_1 = -> {}
      callback_2 = -> {}

      instrument = build_asynchronous_instrument('test-instrument', callback: callback_1)
      assert(instrument.callback == [callback_1])

      instrument = build_asynchronous_instrument('test-instrument', callback: [callback_1, callback_2])
      assert(instrument.callback == [callback_1, callback_2])
    end
  end

  describe '#register_callback' do
    it 'adds to the callback list' do
      callback_1 = -> {}
      callback_2 = -> {}
      callback_3 = -> {}
      instrument = build_asynchronous_instrument('test-instrument')

      instrument.register_callback(callback_1)
      assert(instrument.callback == [callback_1])

      instrument.register_callback([callback_2, callback_3])
      assert(instrument.callback == [callback_1, callback_2, callback_3])

      instrument.register_callback(callback_3)
      assert(instrument.callback == [callback_1, callback_2, callback_3, callback_3])
    end
  end

  describe '#unregister_callback' do
    it 'removes from the callback list' do
      callback_1 = -> {}
      callback_2 = -> {}
      callback_3 = -> {}
      instrument = build_asynchronous_instrument(
        'test-instrument',
        callback: [callback_1, callback_2, callback_3, callback_3]
      )

      instrument.unregister_callback(callback_2)
      assert(instrument.callback == [callback_1, callback_3, callback_3])

      instrument.unregister_callback([callback_1, callback_3])
      assert(instrument.callback == [])
    end
  end

  def build_asynchronous_instrument(*args, **kwargs)
    OpenTelemetry::Metrics::Instrument::AsynchronousInstrument.new(*args, **kwargs)
  end
end
