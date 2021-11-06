# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

require_relative '../../../../lib/opentelemetry/instrumentation/active_record'
require_relative '../../../../lib/opentelemetry/instrumentation/active_record/patches/relation_persistence'

describe OpenTelemetry::Instrumentation::ActiveRecord::Patches::RelationPersistence do
  let(:exporter) { EXPORTER }
  let(:spans) { exporter.finished_spans }

  before { exporter.reset }

  describe '.update_all' do
    it 'traces' do
      User.update_all(name: 'new name')
      update_all_span = spans.find { |s| s.name == 'User.update_all' }
      _(update_all_span).wont_be_nil
      _(spans.count).must_equal(1)
    end

    it 'traces scoped calls' do
      User.recently_created.update_all(name: 'new name')
      update_all_span = spans.find { |s| s.name == 'User.update_all' }
      _(update_all_span).wont_be_nil
      _(spans.count).must_equal(1)
    end
  end

  describe '.delete_all' do
    it 'traces' do
      User.delete_all
      delete_all_span = spans.find { |s| s.name == 'User.delete_all' }
      _(delete_all_span).wont_be_nil
      _(spans.count).must_equal(1)
    end

    it 'traces scoped calls' do
      User.recently_created.delete_all
      delete_all_span = spans.find { |s| s.name == 'User.delete_all' }
      _(delete_all_span).wont_be_nil
      _(spans.count).must_equal(1)
    end
  end
end
