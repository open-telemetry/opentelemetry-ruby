# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::Context::Propagation::RackEnvSetter do
  let(:setter) do
    OpenTelemetry::Context::Propagation::RackEnvSetter.new
  end

  let(:carrier) do
    {
      'traceparent' => 'tp',
      'tracestate' => 'ts',
      'x-source-id' => '123'
    }
  end

  describe '#set' do
    it 'sets the value with Rack env keys' do
      carrier = {}
      setter.set(carrier, 'traceparent', 'tp')
      setter.set(carrier, 'tracestate', 'ts')
      setter.set(carrier, 'x-source-id', '123')
      _(carrier['HTTP_TRACEPARENT']).must_equal('tp')
      _(carrier['HTTP_TRACESTATE']).must_equal('ts')
      _(carrier['HTTP_X_SOURCE_ID']).must_equal('123')
    end
  end
end
