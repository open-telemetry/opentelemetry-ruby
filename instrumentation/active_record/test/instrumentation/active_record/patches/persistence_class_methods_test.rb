# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

require_relative '../../../../lib/opentelemetry/instrumentation/active_record'
require_relative '../../../../lib/opentelemetry/instrumentation/active_record/patches/persistence_class_methods'

describe OpenTelemetry::Instrumentation::ActiveRecord::Patches::Persistence do
  let(:exporter) { EXPORTER }
  let(:spans) { exporter.finished_spans }

  before { exporter.reset }

  describe '.create!' do
    it 'traces' do
      User.create!

      create_span = spans.find { |s| s.name == 'User.create!' }
      _(create_span).wont_be_nil
    end
  end

  describe '.create' do
    it 'traces' do
      User.create

      create_span = spans.find { |s| s.name == 'User.create' }
      _(create_span).wont_be_nil
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
end
