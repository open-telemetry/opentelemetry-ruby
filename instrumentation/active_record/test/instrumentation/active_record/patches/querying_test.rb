# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

require_relative '../../../../lib/opentelemetry/instrumentation/active_record'
require_relative '../../../../lib/opentelemetry/instrumentation/active_record/patches/querying'

describe OpenTelemetry::Instrumentation::ActiveRecord::Patches::Querying do
  let(:exporter) { EXPORTER }
  let(:spans) { exporter.finished_spans }

  before { exporter.reset }

  describe 'find_by_sql' do
    it 'traces' do
      User.find_by_sql('SELECT * FROM users')

      find_span = spans.find { |s| s.name == 'User.find_by_sql' }
      _(find_span).wont_be_nil
    end
  end
end
