# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::Metrics::Meter do
  let(:meter) { OpenTelemetry.meter_provider.meter }
  describe '.create_float_counter' do
    it 'requires a name' do
      _(-> { meter.create_float_counter(nil) }).must_raise(ArgumentError)
    end
    it 'returns a counter' do
      _(meter.create_float_counter('c')).must_respond_to :add
    end
  end
  describe '.create_integer_counter' do
    it 'requires a name' do
      _(-> { meter.create_integer_counter(nil) }).must_raise(ArgumentError)
    end
    it 'returns a counter' do
      _(meter.create_integer_counter('c')).must_respond_to :add
    end
  end
  describe '.create_float_measure' do
    it 'requires a name' do
      _(-> { meter.create_float_measure(nil) }).must_raise(ArgumentError)
    end
    it 'returns a measure' do
      _(meter.create_float_measure('m')).must_respond_to :record
    end
  end
  describe '.create_integer_measure' do
    it 'requires a name' do
      _(-> { meter.create_integer_measure(nil) }).must_raise(ArgumentError)
    end
    it 'returns a measure' do
      _(meter.create_integer_measure('m')).must_respond_to :record
    end
  end
end
