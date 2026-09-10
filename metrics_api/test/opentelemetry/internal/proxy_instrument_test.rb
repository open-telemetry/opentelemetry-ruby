# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::Internal::ProxyInstrument do
  let(:proxy_meter_provider) { OpenTelemetry::Internal::ProxyMeterProvider.new }
  let(:proxy_meter) { proxy_meter_provider.meter('test-meter') }
  let(:advisory) { { explicit_bucket_boundaries: [0, 5, 10], attributes: ['http.request.method'] } }

  def install_delegate
    proxy_meter_provider.delegate = OpenTelemetry::Metrics::MeterProvider.new
  end

  describe 'before a delegate is installed' do
    it 'returns proxy instruments' do
      _(proxy_meter).must_be_instance_of(OpenTelemetry::Internal::ProxyMeter)
      _(proxy_meter.create_counter('c')).must_be_instance_of(OpenTelemetry::Internal::ProxyInstrument)
    end

    it 'recording operations are no-ops that return nil' do
      _(proxy_meter.create_counter('c').add(1)).must_be_nil
      _(proxy_meter.create_histogram('h').record(1)).must_be_nil
    end

    it '#enabled? returns false' do
      _(proxy_meter.create_counter('c').enabled?).must_equal(false)
    end

    it 'retains advisory parameters for the eventual delegate' do
      instrument = proxy_meter.create_histogram('h', advisory: advisory)
      _(instrument.instance_variable_get(:@advisory)).must_equal(advisory)
    end

    it 'queues callbacks registered on asynchronous instruments' do
      callback = -> {}
      instrument = proxy_meter.create_observable_counter('oc')
      instrument.register_callback(callback)
      _(instrument.instance_variable_get(:@registered_callbacks)).must_equal([callback])
    end

    it 'removes a queued callback on unregister' do
      callback = -> {}
      instrument = proxy_meter.create_observable_counter('oc')
      instrument.register_callback(callback)
      instrument.unregister(callback)
      _(instrument.instance_variable_get(:@registered_callbacks)).must_be_empty
    end
  end

  describe 'after a delegate is installed' do
    it 'upgrades synchronous instruments created beforehand' do
      instrument = proxy_meter.create_counter('c')
      install_delegate
      _(instrument.instance_variable_get(:@delegate)).must_be_instance_of(OpenTelemetry::Metrics::Instrument::Counter)
    end

    it 'upgrades asynchronous instruments created beforehand' do
      instrument = proxy_meter.create_observable_counter('oc', callback: -> {})
      install_delegate
      _(instrument.instance_variable_get(:@delegate)).must_be_instance_of(OpenTelemetry::Metrics::Instrument::ObservableCounter)
    end

    it 'upgrades instruments created with advisory parameters' do
      instrument = proxy_meter.create_histogram('h', advisory: advisory)
      install_delegate
      _(instrument.instance_variable_get(:@delegate)).must_be_instance_of(OpenTelemetry::Metrics::Instrument::Histogram)
    end

    it 'replays queued callbacks onto the delegate' do
      callback = -> {}
      instrument = proxy_meter.create_observable_counter('oc')
      instrument.register_callback(callback)

      install_delegate

      delegate = instrument.instance_variable_get(:@delegate)
      _(delegate).must_be_instance_of(OpenTelemetry::Metrics::Instrument::ObservableCounter)
      # queued callbacks are forwarded, not re-queued
      _(instrument.register_callback(-> {})).must_be_nil
    end

    it 'delegates #enabled? to the upgraded instrument' do
      instrument = proxy_meter.create_counter('c')
      install_delegate
      _(instrument.enabled?).must_equal(instrument.instance_variable_get(:@delegate).enabled?)
    end

    it 'delegates recording operations to the upgraded instrument' do
      counter = proxy_meter.create_counter('c')
      histogram = proxy_meter.create_histogram('h')
      install_delegate
      _(counter.add(1)).must_be_nil
      _(histogram.record(1)).must_be_nil
    end
  end

  describe '#upgrade_with' do
    # Captures the arguments the proxy forwards when it builds the real instrument.
    let(:capturing_meter) do
      Class.new do
        attr_reader :kwargs

        def initialize(instrument)
          @instrument = instrument
        end

        def create_histogram(_name, **kwargs)
          @kwargs = kwargs
          @instrument
        end

        def create_observable_counter(_name, **kwargs)
          @kwargs = kwargs
          @instrument
        end
      end
    end

    it 'forwards advisory parameters to the real instrument' do
      meter = capturing_meter.new(OpenTelemetry::Metrics::Instrument::Histogram.new)
      instrument = OpenTelemetry::Internal::ProxyInstrument.new(:histogram, 'h', 's', 'desc', nil, nil, nil, advisory)

      instrument.upgrade_with(meter)

      _(meter.kwargs[:advisory]).must_equal(advisory)
    end

    it 'forwards the creation-time callback to the real instrument' do
      callback = -> {}
      meter = capturing_meter.new(OpenTelemetry::Metrics::Instrument::ObservableCounter.new)
      instrument = OpenTelemetry::Internal::ProxyInstrument.new(:observable_counter, 'oc', nil, nil, callback, nil, nil, nil)

      instrument.upgrade_with(meter)

      _(meter.kwargs[:callback]).must_equal(callback)
    end

    it 'registers queued callbacks on the real instrument' do
      callback = -> {}
      delegate = Class.new(OpenTelemetry::Metrics::Instrument::ObservableCounter) do
        attr_reader :registered

        def register_callback(callback)
          (@registered ||= []) << callback
        end
      end.new
      meter = capturing_meter.new(delegate)

      instrument = OpenTelemetry::Internal::ProxyInstrument.new(:observable_counter, 'oc', nil, nil, nil, nil, nil, nil)
      instrument.register_callback(callback)
      instrument.upgrade_with(meter)

      _(delegate.registered).must_equal([callback])
    end
  end
end
