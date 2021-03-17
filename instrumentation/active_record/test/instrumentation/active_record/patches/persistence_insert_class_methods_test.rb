# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

require_relative '../../../../lib/opentelemetry/instrumentation/active_record'
require_relative '../../../../lib/opentelemetry/instrumentation/active_record/patches/persistence_insert_class_methods'

describe OpenTelemetry::Instrumentation::ActiveRecord::Patches::PersistenceInsertClassMethods do
  let(:exporter) { EXPORTER }
  let(:spans) { exporter.finished_spans }

  before do
    exporter.reset
    skip if Gem.loaded_specs['activerecord'].version < Gem::Version.new('6.0.0')
  end

  describe '.insert' do
    it 'traces' do
      User.insert({ updated_at: Time.current, created_at: Time.current })
      insert_span = spans.find { |s| s.name == 'User.insert' }
      _(insert_span).wont_be_nil
    end
  end

  describe '.insert_all' do
    it 'traces' do
      User.insert_all([{ updated_at: Time.current, created_at: Time.current }])
      insert_all_span = spans.find { |s| s.name == 'User.insert_all' }
      _(insert_all_span).wont_be_nil
    end
  end

  describe '.insert!' do
    it 'traces' do
      User.insert!({ updated_at: Time.current, created_at: Time.current })
      insert_span = spans.find { |s| s.name == 'User.insert!' }
      _(insert_span).wont_be_nil
    end
  end

  describe '.insert_all!' do
    it 'traces' do
      User.insert_all!([{ updated_at: Time.current, created_at: Time.current }])
      insert_all_span = spans.find { |s| s.name == 'User.insert_all!' }
      _(insert_all_span).wont_be_nil
    end
  end

  describe '.upsert' do
    it 'traces' do
      User.upsert({ updated_at: Time.current, created_at: Time.current })
      upsert_span = spans.find { |s| s.name == 'User.upsert' }
      _(upsert_span).wont_be_nil
    end
  end

  describe '.upsert_all' do
    it 'traces' do
      User.upsert_all([{ updated_at: Time.current, created_at: Time.current }])
      upsert_all_span = spans.find { |s| s.name == 'User.upsert_all' }
      _(upsert_all_span).wont_be_nil
    end
  end
end
