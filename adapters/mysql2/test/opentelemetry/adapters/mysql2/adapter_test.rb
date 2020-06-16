# frozen_string_literal: true

# Copyright 2020 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

require_relative '../../../../lib/opentelemetry/adapters/mysql2'
require_relative '../../../../lib/opentelemetry/adapters/mysql2/patches/client'

describe OpenTelemetry::Adapters::Mysql2::Adapter do
  let(:adapter) { OpenTelemetry::Adapters::Mysql2::Adapter.instance }
  let(:exporter) { EXPORTER }
  let(:span) { exporter.finished_spans.first }

  before do
    exporter.reset
  end

  after do
    # Force re-install of instrumentation
    adapter.instance_variable_set(:@installed, false)
  end

  describe 'tracing' do
    before do
      adapter.install
    end

    it 'before request' do
      _(exporter.finished_spans.size).must_equal 0
    end

    # it 'after requests' do
    # end

    # it 'after error' do
    # end
  end
end
