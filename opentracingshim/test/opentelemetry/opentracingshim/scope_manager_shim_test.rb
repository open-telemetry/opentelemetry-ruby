# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::OpenTracingShim::ScopeManagerShim do
  let(:mock_tracer) { Minitest::Mock.new }
  let(:scope_manager_shim) { OpenTelemetry::OpenTracingShim::ScopeManagerShim.new mock_tracer }
  describe '#activate' do
    it 'marks the current span as active' do
    end
  end

  describe '#active' do
    it 'returns the tracers current_span' do
      span = 'span'
      mock_tracer.expect(:current_span, span)
      span_shim = scope_manager_shim.active
      span_shim.span.must_equal(span)
      mock_tracer.verify
    end
  end
end
