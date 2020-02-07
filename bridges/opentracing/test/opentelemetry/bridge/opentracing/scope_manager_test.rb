# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::Bridge::OpenTracing::ScopeManager do
  let(:scope_manager_bridge) { OpenTelemetry::Bridge::OpenTracing::ScopeManager.instance }
  describe '#activate' do
    before do
      scope_manager_bridge.active = nil
    end

    it 'marks the given span as active' do
      span = 'span'
      scope_manager_bridge.activate(span, finish_on_close: true)
      scope_manager_bridge.active.must_be_instance_of OpenTelemetry::Bridge::OpenTracing::Scope
      scope_manager_bridge.active.span.must_equal span
    end
  end

  describe '#active' do
    before do
      scope_manager_bridge.active = nil
    end

    it 'returns nil if not set' do
      scope_manager_bridge.active.must_be_nil
      scope_manager_bridge.active = nil
    end

    it 'sets and returns a given scope' do
      scope = 'scope'
      scope_manager_bridge.active.must_be_nil
      scope_manager_bridge.active = scope
      scope_manager_bridge.active.must_equal scope
      scope_manager_bridge.active = nil
    end
  end
end
