# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

require_relative '../../../../lib/opentelemetry/instrumentation/active_record'
require_relative '../../../../lib/opentelemetry/instrumentation/active_record/patches/persistence'

describe OpenTelemetry::Instrumentation::ActiveRecord::Patches::Persistence do
  let(:exporter) { EXPORTER }
  let(:spans) { exporter.finished_spans }

  before { exporter.reset }

  describe '#save!' do
    it 'traces' do
      User.new.save!
      save_span = spans.find { |s| s.name == 'User#save!' }
      _(save_span).wont_be_nil
    end
  end

  describe '#save' do
    it 'traces' do
      User.new.save
      save_span = spans.find { |s| s.name == 'User#save' }
      _(save_span).wont_be_nil
    end
  end

  describe '#delete' do
    it 'traces' do
      User.new.delete
      delete_span = spans.find { |s| s.name == 'User#delete' }
      _(delete_span).wont_be_nil
    end
  end

  describe '#destroy!' do
    it 'traces' do
      User.new.destroy!
      destroy_span = spans.find { |s| s.name == 'User#destroy!' }
      _(destroy_span).wont_be_nil
    end
  end

  describe '#destroy' do
    it 'traces' do
      User.new.destroy
      destroy_span = spans.find { |s| s.name == 'User#destroy' }
      _(destroy_span).wont_be_nil
    end
  end

  describe '#update!' do
    it 'traces' do
      User.new.update!(updated_at: Time.current)
      update_span = spans.find { |s| s.name == 'User#update!' }
      _(update_span).wont_be_nil
    end
  end

  describe '#update' do
    it 'traces' do
      User.new.update(updated_at: Time.current)
      update_span = spans.find { |s| s.name == 'User#update' }
      _(update_span).wont_be_nil
    end
  end
end
