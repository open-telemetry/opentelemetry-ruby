# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::Bridge::OpenTracing::Scope do
  OpenTelemetry.tracer = Minitest::Mock.new
  let(:scope_bridge) { OpenTelemetry::Bridge::OpenTracing::Scope.new }
  describe '#span' do
    it 'gets the current span' do
      OpenTelemetry.tracer.expect(:current_span, 'an_active_span')
      as = scope_bridge.span
      as.must_equal 'an_active_span'
      OpenTelemetry.tracer.verify
    end
  end

  describe '#close' do
    it 'calls finish on the tracers current span' do
      mock_span = Minitest::Mock.new
      OpenTelemetry.tracer.expect(:current_span, mock_span)
      mock_span.expect(:finish, nil)
      scope_bridge.close
      OpenTelemetry.tracer.verify
      mock_span.verify
    end
  end
end
