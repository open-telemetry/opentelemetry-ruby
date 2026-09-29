# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::Internal::ProxyMeter do
  # Records every instrument created on it by an upgrading proxy.
  class RecordingDelegateMeter < OpenTelemetry::Metrics::Meter
    attr_reader :created

    def initialize
      super
      @created = []
    end

    private

    def create_instrument(kind, name, unit, description, callback, exemplar_filter, exemplar_reservoir)
      @created << { kind: kind, name: name, unit: unit }
      super
    end
  end

  let(:proxy_meter) { OpenTelemetry::Internal::ProxyMeter.new }
  let(:delegate_meter) { RecordingDelegateMeter.new }

  describe '#delegate=' do
    it 'upgrades every placeholder of a repeated registration' do
      first = proxy_meter.create_counter('a_counter')
      second = proxy_meter.create_counter('a_counter')

      proxy_meter.delegate = delegate_meter

      _(first.instance_variable_get(:@delegate)).wont_be_nil
      _(second.instance_variable_get(:@delegate)).wont_be_nil
    end

    it 'upgrades every placeholder of a conflicting registration' do
      first = proxy_meter.create_counter('a_counter', unit: 'smidgen')
      second = proxy_meter.create_counter('a_counter', unit: 'flurbo')

      proxy_meter.delegate = delegate_meter

      _(first.instance_variable_get(:@delegate)).wont_be_nil
      _(second.instance_variable_get(:@delegate)).wont_be_nil
      _(delegate_meter.created).must_equal(
        [
          { kind: :counter, name: 'a_counter', unit: 'smidgen' },
          { kind: :counter, name: 'a_counter', unit: 'flurbo' }
        ]
      )
    end

    it 'does not keep placeholders once the delegate is set' do
      proxy_meter.create_counter('a_counter')
      proxy_meter.delegate = delegate_meter

      _(proxy_meter.instance_variable_get(:@proxy_instruments)).must_be_empty
    end
  end

  describe '#create_counter after the delegate is set' do
    it 'returns the delegate instrument instead of a placeholder' do
      proxy_meter.delegate = delegate_meter

      _(proxy_meter.create_counter('a_counter')).wont_be_instance_of(OpenTelemetry::Internal::ProxyInstrument)
      _(proxy_meter.instance_variable_get(:@proxy_instruments)).must_be_empty
      _(delegate_meter.created).must_equal([{ kind: :counter, name: 'a_counter', unit: nil }])
    end
  end
end
