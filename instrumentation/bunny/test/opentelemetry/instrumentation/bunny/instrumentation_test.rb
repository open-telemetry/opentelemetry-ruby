# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

require_relative '../../../../lib/opentelemetry/instrumentation/bunny'

describe OpenTelemetry::Instrumentation::Bunny::Instrumentation do
  let(:instrumentation) { OpenTelemetry::Instrumentation::Bunny::Instrumentation.instance }

  it 'has #name' do
    _(instrumentation.name).must_equal 'OpenTelemetry::Instrumentation::Bunny'
  end

  it 'has #version' do
    _(instrumentation.version).wont_be_nil
    _(instrumentation.version).wont_be_empty
  end

  describe '#install' do
    it 'accepts arguments' do
      instrumentation.instance_variable_set(:@installed, false)
      _(instrumentation.install({})).must_equal(true)
    end
  end
end
