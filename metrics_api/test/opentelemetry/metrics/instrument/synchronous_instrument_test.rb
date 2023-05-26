# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::Metrics::Instrument::SynchronousInstrument do
  describe '#name' do
    it 'returns name' do
      instrument = build_synchronous_instrument('test-instrument')

      assert(instrument.name == 'test-instrument')
    end
  end

  describe '#unit' do
    it 'returns unit' do
      instrument = build_synchronous_instrument('test-instrument')
      assert(instrument.unit == '')

      instrument = build_synchronous_instrument('test-instrument', unit: 'b')
      assert(instrument.unit == 'b')
    end
  end

  describe '#description' do
    it 'returns description' do
      instrument = build_synchronous_instrument('test-instrument')
      assert(instrument.description == '')

      instrument = build_synchronous_instrument('test-instrument', description: 'bytes received')
      assert(instrument.description == 'bytes received')
    end
  end

  describe '#advice' do
    it 'returns advice' do
      instrument = build_synchronous_instrument('test-instrument')
      assert(instrument.advice == {})

      instrument = build_synchronous_instrument(
        'test-instrument',
        advice: {
          histogram: {
            explicit_bucket_boundaries: [0.1, 0.5, 1.0, 5.0, 10.0, 25.0, Float::INFINITY]
          }
        }
      )
      assert(instrument.advice == {
        histogram: {
          explicit_bucket_boundaries: [0.1, 0.5, 1.0, 5.0, 10.0, 25.0, Float::INFINITY]
        }
      })
    end
  end

  def build_synchronous_instrument(*args, **kwargs)
    OpenTelemetry::Metrics::Instrument::SynchronousInstrument.new(*args, **kwargs)
  end
end
