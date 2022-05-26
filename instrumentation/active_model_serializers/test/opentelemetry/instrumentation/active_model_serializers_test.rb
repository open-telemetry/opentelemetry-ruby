# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require_relative '../../test_helper'

describe OpenTelemetry::Instrumentation::ActiveModelSerializers do
  let(:instrumentation) { OpenTelemetry::Instrumentation::ActiveModelSerializers::Instrumentation.instance }
  let(:exporter) { EXPORTER }

  before do
    instrumentation.install
    exporter.reset
  end

  describe 'present' do
    it 'when active_model_serializers gem installed' do
      _(instrumentation.present?).must_equal true
    end

    it 'when active_model_serializers gem not installed' do
      hide_const('::ActiveModelSerializers')
      _(instrumentation.present?).must_equal false
    end
  end

  describe 'compatible' do
    it 'when older gem version installed' do
      stub_const('::ActiveModel::Serializer::VERSION', '0.9.4')
      _(instrumentation.compatible?).must_equal false
    end

    it 'when future gem version installed' do
      _(instrumentation.compatible?).must_equal true
    end
  end

  describe 'install' do
    it 'subscribes to ActiveSupport::Notifications' do
      subscriptions = ActiveSupport::Notifications.notifier.instance_variable_get(:'@string_subscribers')
      subscriptions = subscriptions['render.active_model_serializers']
      assert(subscriptions.detect { |s| s.is_a?(ActiveSupport::Notifications::Fanout::Subscribers::Timed) })
    end
  end
end
