# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

require_relative '../../../../lib/opentelemetry/instrumentation/active_record'
require_relative '../../../../lib/opentelemetry/instrumentation/active_record/patches/transactions_class_methods'

describe OpenTelemetry::Instrumentation::ActiveRecord::Patches::TransactionsClassMethods do
  let(:exporter) { EXPORTER }
  let(:spans) { exporter.finished_spans }

  before { exporter.reset }

  describe '.transaction' do
    it 'traces' do
      User.transaction { User.create! }

      transaction_span = spans.find { |s| s.name == 'User.transaction' }
      _(transaction_span).wont_be_nil
    end

    it 'traces base transactions' do
      ActiveRecord::Base.transaction { User.create! }

      transaction_span = spans.find { |s| s.name == 'ActiveRecord::Base.transaction' }
      _(transaction_span).wont_be_nil
    end
  end
end
