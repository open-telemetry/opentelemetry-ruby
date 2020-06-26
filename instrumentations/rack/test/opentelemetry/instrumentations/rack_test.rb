# frozen_string_literal: true

# Copyright 2020 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

require_relative '../../../lib/opentelemetry/instrumentations/rack'

describe OpenTelemetry::Instrumentations::Rack do
  let(:instrumentation) { OpenTelemetry::Instrumentations::Rack::Instrumentation.instance }

  it 'has #name' do
    _(instrumentation.name).must_equal 'OpenTelemetry::Instrumentations::Rack'
  end

  it 'has #version' do
    _(instrumentation.version).wont_be_nil
    _(instrumentation.version).wont_be_empty
  end

  describe '#install' do
    it 'accepts argument' do
      instrumentation.install({})
    end
  end
end
