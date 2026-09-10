# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::Metrics::Instrument do
  let(:attributes) { { 'http.request.method' => 'GET' } }

  describe 'synchronous instruments' do
    [
      [OpenTelemetry::Metrics::Instrument::Counter, :add],
      [OpenTelemetry::Metrics::Instrument::UpDownCounter, :add],
      [OpenTelemetry::Metrics::Instrument::Histogram, :record],
      [OpenTelemetry::Metrics::Instrument::Gauge, :record]
    ].each do |klass, record_op|
      describe klass do
        let(:instrument) { klass.new }

        it "##{record_op} returns nil and retains no state" do
          _(instrument.public_send(record_op, 1)).must_be_nil
          _(instrument.public_send(record_op, 2, attributes: attributes)).must_be_nil
        end

        it '#enabled? returns true' do
          _(instrument.enabled?).must_equal(true)
        end

        it '#bind returns an instrument supporting the recording operation' do
          bound = instrument.bind(attributes: attributes)
          _(bound).must_respond_to(record_op)
          _(bound.public_send(record_op, 1)).must_be_nil
        end

        it '#bind accepts no attributes' do
          _(instrument.bind).must_respond_to(record_op)
        end
      end
    end
  end

  describe 'asynchronous instruments' do
    [
      OpenTelemetry::Metrics::Instrument::ObservableCounter,
      OpenTelemetry::Metrics::Instrument::ObservableUpDownCounter,
      OpenTelemetry::Metrics::Instrument::ObservableGauge
    ].each do |klass|
      describe klass do
        let(:instrument) { klass.new }
        let(:callback) { -> {} }

        it '#observe returns nil' do
          _(instrument.observe).must_be_nil
          _(instrument.observe(timeout: 1, attributes: attributes)).must_be_nil
        end

        it '#register_callback returns nil and does not raise' do
          _(instrument.register_callback(callback)).must_be_nil
        end

        it '#unregister returns nil and does not raise' do
          instrument.register_callback(callback)
          _(instrument.unregister(callback)).must_be_nil
        end
      end
    end
  end
end
