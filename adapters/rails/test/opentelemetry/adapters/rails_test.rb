# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

require_relative '../../../lib/opentelemetry/adapters/rails/adapter'

class RailsAdapterTest < ActionDispatch::IntegrationTest

  setup do
    @adapter = OpenTelemetry::Adapters::Rails::Adapter.instance
    @exporter = EXPORTER
    @adapter.install
    @exporter.reset
  end

  def test_no_finished_spans_before_request
    assert_equal @exporter.finished_spans.size, 0
  end

  def test_one_finished_span_after_request
    get '/full'
    assert_equal @exporter.finished_spans.size, 1
  end
end
