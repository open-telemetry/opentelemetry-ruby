# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

require_relative '../../../../lib/opentelemetry/adapters/faraday/adapter'

describe OpenTelemetry::Adapters::Faraday::Adapter do
  let(:adapter) { OpenTelemetry::Adapters::Faraday::Adapter }

  before do
    adapter.install
  end

  describe 'defaults' do
    it 'has propagator' do
      _(adapter.propagator).wont_be_nil
    end

    it 'has tracer' do
      _(adapter.tracer).wont_be_nil
    end
  end
end
