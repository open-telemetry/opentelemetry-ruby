# frozen_string_literal: true

# Copyright 2020 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

require_relative '../../../../../../lib/opentelemetry/instrumentation/ruby_kafka'
require_relative '../../../../../../lib/opentelemetry/instrumentation/ruby_kafka/events/consumer/process_batch'

describe OpenTelemetry::Instrumentation::RubyKafka::Events::Consumer::ProcessBatch do
  let(:described_class) { OpenTelemetry::Instrumentation::RubyKafka::Events::Consumer::ProcessBatch }
  let(:instrumentation) { OpenTelemetry::Instrumentation::RubyKafka::Instrumentation.instance }
  let(:exporter) { EXPORTER }
  let(:spans) { exporter.finished_spans }
  let(:span) { spans.first }
  let(:group_id) { SecureRandom.uuid }
  let(:topic) { 'my-topic' }
  let(:message_count) { rand(1..10) }
  let(:partition) { rand(0..100) }
  let(:highwater_mark_offset) { rand(100..1000) }
  let(:offset_lag) { rand(1..1000) }
  let(:payload) do
    {
      group_id: group_id,
      topic: topic,
      message_count: message_count,
      partition: partition,
      highwater_mark_offset: highwater_mark_offset,
      offset_lag: offset_lag
    }
  end

  before do
    # Clear spans
    exporter.reset

    instrumentation.install
  end

  after do
    # Force re-install of instrumentation
    instrumentation.instance_variable_set(:@installed, false)
    clear_notification_subscriptions
  end

  it 'produces a span' do
    ActiveSupport::Notifications.instrument(described_class::EVENT_NAME, payload)

    _(spans.size).must_equal(1)

    _(span.name).must_equal('kafka.consumer.process_batch')
    _(span.start_timestamp).must_be_instance_of(Time)
    _(span.end_timestamp).must_be_instance_of(Time)

    _(span.attributes['messaging.system']).must_equal('kafka')
    _(span.attributes['topic']).must_equal(topic)
    _(span.attributes['message_count']).must_equal(message_count)
    _(span.attributes['partition']).must_equal(partition)
    _(span.attributes['highwater_mark_offset']).must_equal(highwater_mark_offset)
    _(span.attributes['offset_lag']).must_equal(offset_lag)
  end
end
