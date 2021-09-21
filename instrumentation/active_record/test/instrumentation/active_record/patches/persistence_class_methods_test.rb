# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

require_relative '../../../../lib/opentelemetry/instrumentation/active_record'
require_relative '../../../../lib/opentelemetry/instrumentation/active_record/patches/persistence_class_methods'

describe OpenTelemetry::Instrumentation::ActiveRecord::Patches::PersistenceClassMethods do
  let(:exporter) { EXPORTER }
  let(:spans) { exporter.finished_spans }

  before { exporter.reset }

  describe '.create' do
    it 'traces' do
      User.create
      create_span = spans.find { |s| s.name == 'User.create' }
      _(create_span).wont_be_nil
    end
  end

  describe '.create!' do
    it 'traces' do
      User.create!
      create_span = spans.find { |s| s.name == 'User.create!' }
      _(create_span).wont_be_nil
    end

    it 'adds an exception event if it raises' do
      _(-> { User.create!(attreeboot: 1) }).must_raise(ActiveModel::UnknownAttributeError)

      create_span = spans.find { |s| s.name == 'User.create!' }
      _(create_span).wont_be_nil
      create_span_event = create_span.events.first
      _(create_span_event.attributes['exception.type']).must_equal('ActiveModel::UnknownAttributeError')
      _(create_span_event.attributes['exception.message']).must_equal('unknown attribute \'attreeboot\' for User.')
    end
  end

  describe '.update' do
    it 'traces' do
      last_user = User.create
      User.update(last_user.id, updated_at: Time.now)
      update_span = spans.find { |s| s.name == 'User.update' }
      _(update_span).wont_be_nil
    end
  end

  describe '.destroy' do
    it 'traces' do
      new_user = User.create
      User.destroy(new_user.id)
      destroy_span = spans.find { |s| s.name == 'User.destroy' }
      _(destroy_span).wont_be_nil
    end
  end

  describe '.delete' do
    it 'traces' do
      new_user = User.create
      User.delete(new_user.id)
      delete_span = spans.find { |s| s.name == 'User.delete' }
      _(delete_span).wont_be_nil
    end
  end
end
