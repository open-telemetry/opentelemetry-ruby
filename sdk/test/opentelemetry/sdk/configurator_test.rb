# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::SDK::Configurator do
  let(:configurator) { OpenTelemetry::SDK::Configurator.new }

  describe '#tracer_factory' do
    it 'defaults to SDK::Trace::TracerFactory' do
      _(configurator.tracer_factory).must_be_instance_of(
        OpenTelemetry::SDK::Trace::TracerFactory
      )
    end
  end

  describe '#logger' do
    it 'returns a logger instance' do
      _(configurator.logger).must_be_instance_of(Logger)
    end
  end

  describe '#use' do
    it 'can be called multiple times' do
      configurator.use('TestAdapter', enabled: true)
      configurator.use('TestAdapter1')
    end
  end

  describe '#use, #use_all' do
    describe 'should be used mutually exclusively' do
      it 'raises when use_all called after use' do
        configurator.use('TestAdapter', enabled: true)
        _(-> { configurator.use_all }).must_raise(StandardError)
      end

      it 'raises when use called after use_all' do
        configurator.use_all
        _(-> { configurator.use('TestAdapter', enabled: true) })
          .must_raise(StandardError)
      end
    end
  end
end
