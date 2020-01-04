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
end
