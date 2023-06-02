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

  describe '#callbacks' do
    it 'returns callbacks list' do
      instrument = build_asynchronous_instrument('test-instrument')
      assert(instrument.callbacks == [])

      callback_1 = -> {}
      callback_2 = -> {}

      instrument = build_asynchronous_instrument('test-instrument', callbacks: callback_1)
      assert(instrument.callbacks == [callback_1])

      instrument = build_asynchronous_instrument('test-instrument', callbacks: [callback_1, callback_2])
      assert(instrument.callbacks == [callback_1, callback_2])
    end
  end

  describe '#register_callbacks' do
    it 'responds without errors and returns nil' do
      instrument = build_asynchronous_instrument('test-instrument')

      assert(instrument.register_callbacks(-> {}).nil?)
      assert(instrument.register_callbacks([-> {}, -> {}]).nil?)
    end
  end

  describe '#unregister_callbacks' do
    it 'responds without errors and returns nil' do
      instrument = build_asynchronous_instrument('test-instrument')

      assert(instrument.unregister_callbacks(-> {}).nil?)
      assert(instrument.unregister_callbacks([-> {}, -> {}]).nil?)
    end
  end

  def build_asynchronous_instrument(*args, **kwargs)
    OpenTelemetry::Metrics::Instrument::AsynchronousInstrument.new(*args, **kwargs)
  end
end
