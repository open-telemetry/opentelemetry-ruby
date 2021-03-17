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

  describe '#save' do
    it 'traces' do
      User.new.save
      save_span = spans.find { |s| s.name == 'User#save' }
      _(save_span).wont_be_nil
    end
  end

  describe '#save!' do
    it 'traces' do
      User.new.save!
      save_span = spans.find { |s| s.name == 'User#save!' }
      _(save_span).wont_be_nil
    end

    it 'adds an exception event if it raises' do
      _(-> { User.new(name: 'not otel').save! }).must_raise(ActiveRecord::RecordInvalid)

      save_span = spans.find { |s| s.name == 'User#save!' }
      _(save_span).wont_be_nil
      save_span_event = save_span.events.first
      _(save_span_event.attributes['exception.type']).must_equal('ActiveRecord::RecordInvalid')
      _(save_span_event.attributes['exception.message']).must_equal('Validation failed: must be otel')
    end
  end

  describe '#delete' do
    it 'traces' do
      User.new.delete
      delete_span = spans.find { |s| s.name == 'User#delete' }
      _(delete_span).wont_be_nil
    end
  end

  describe '#destroy' do
    it 'traces' do
      User.new.destroy
      destroy_span = spans.find { |s| s.name == 'User#destroy' }
      _(destroy_span).wont_be_nil
    end
  end

  describe '#destroy!' do
    it 'traces' do
      User.new.destroy!
      destroy_span = spans.find { |s| s.name == 'User#destroy!' }
      _(destroy_span).wont_be_nil
    end
  end

  describe '#becomes' do
    it 'traces' do
      User.new.becomes(SuperUser)
      becomes_span = spans.find { |s| s.name == 'User#becomes' }
      _(becomes_span).wont_be_nil
    end
  end

  describe '#becomes!' do
    it 'traces' do
      _(-> { User.new.becomes!(SuperUser) }).must_raise(NoMethodError)

      becomes_span = spans.find { |s| s.name == 'User#becomes!' }
      _(becomes_span).wont_be_nil
      becomes_span = becomes_span.events.first
      _(becomes_span.attributes['exception.type']).must_equal('NoMethodError')
    end
  end

  describe '#update_attribute' do
    it 'traces' do
      User.new.update_attribute('updated_at', Time.current)
      update_attribute_span = spans.find { |s| s.name == 'User#update_attribute' }
      _(update_attribute_span).wont_be_nil
    end
  end

  describe '#update' do
    it 'traces' do
      User.new.update(updated_at: Time.current)
      update_span = spans.find { |s| s.name == 'User#update' }
      _(update_span).wont_be_nil
    end
  end

  describe '#update!' do
    it 'traces' do
      User.new.update!(updated_at: Time.current)
      update_span = spans.find { |s| s.name == 'User#update!' }
      _(update_span).wont_be_nil
    end
  end

  describe '#update_column' do
    it 'traces' do
      new_user = User.new
      new_user.save
      new_user.update_column(:updated_at, Time.current)

      update_column_span = spans.find { |s| s.name == 'User#update_column' }
      _(update_column_span).wont_be_nil
    end
  end

  describe '#update_columns' do
    it 'traces' do
      new_user = User.new
      new_user.save
      new_user.update_columns(updated_at: Time.current, name: 'otel')

      update_column_span = spans.find { |s| s.name == 'User#update_columns' }
      _(update_column_span).wont_be_nil
    end
  end

  describe '#increment' do
    it 'traces' do
      User.new.increment(:counter)
      increment_span = spans.find { |s| s.name == 'User#increment' }
      _(increment_span).wont_be_nil
    end
  end

  describe '#increment!' do
    it 'traces' do
      User.new.increment!(:counter)
      increment_span = spans.find { |s| s.name == 'User#increment!' }
      _(increment_span).wont_be_nil
    end
  end

  describe '#decrement' do
    it 'traces' do
      User.new.decrement(:counter)
      decrement_span = spans.find { |s| s.name == 'User#decrement' }
      _(decrement_span).wont_be_nil
    end
  end

  describe '#decrement!' do
    it 'traces' do
      User.new.decrement!(:counter)
      decrement_span = spans.find { |s| s.name == 'User#decrement!' }
      _(decrement_span).wont_be_nil
    end
  end

  describe '#toggle' do
    it 'traces' do
      User.new.toggle(:counter)
      toggle_span = spans.find { |s| s.name == 'User#toggle' }
      _(toggle_span).wont_be_nil
    end
  end

  describe '#toggle!' do
    it 'traces' do
      User.new.toggle!(:counter)
      toggle_span = spans.find { |s| s.name == 'User#toggle!' }
      _(toggle_span).wont_be_nil
    end
  end

  describe '#reload' do
    it 'traces' do
      new_user = User.new
      new_user.save
      new_user.reload
      reload_span = spans.find { |s| s.name == 'User#reload' }
      _(reload_span).wont_be_nil
    end
  end

  describe '#touch' do
    it 'traces' do
      new_user = User.new
      new_user.save
      new_user.touch
      touch_span = spans.find { |s| s.name == 'User#touch' }
      _(touch_span).wont_be_nil
    end
  end
end
