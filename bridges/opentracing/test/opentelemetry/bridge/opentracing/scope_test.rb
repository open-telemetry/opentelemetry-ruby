# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::Bridge::OpenTracing::Scope do
  Scope = OpenTelemetry::Bridge::OpenTracing::Scope
  let(:span) { 'a_span' }
  let(:mock_span) { Minitest::Mock.new }
  let(:manager) { OpenTelemetry::Bridge::OpenTracing::ScopeManager.instance }
  describe '#span' do
    it 'gets the current span' do
      scope = Scope.new(manager, span, true)
      scope.span.must_equal span
    end
  end

  describe '#close' do
    it 'calls finish on the current span if finish_on_close' do
      mock_span.expect(:finish, nil)
      scope = Scope.new(manager, mock_span, true)
      scope.close
      mock_span.verify
    end

    it 'does not calls finish on the current span if not finish_on_close' do
      scope = Scope.new(manager, mock_span, false)
      scope.close
      mock_span.verify
    end

    it 'sets manager active to parent on close' do
      manager.active = 'a_parent'
      scope = Scope.new(manager, mock_span, false)
      scope.close
      mock_span.verify
      manager.active.must_equal 'a_parent'
    end
  end
end
