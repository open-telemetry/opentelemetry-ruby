# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::OpenTracingBridge::ScopeManager do
  let(:mock_tracer) { Minitest::Mock.new }
  let(:scope_manager_bridge) { OpenTelemetry::OpenTracingBridge::ScopeManager.new mock_tracer }
  describe '#activate' do
    it 'marks the current span as active' do
    end
  end

  describe '#active' do
    it 'returns the tracers current_span' do
      span = 'span'
      mock_tracer.expect(:current_span, span)
      span_bridge = scope_manager_bridge.active
      span_bridge.span.must_equal(span)
      mock_tracer.verify
    end
  end
end
