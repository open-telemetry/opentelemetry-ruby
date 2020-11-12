# frozen_string_literal: true

# Copyright 2020 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

require_relative '../../../../../../lib/opentelemetry/instrumentation/ruby_kafka'
require_relative '../../../../../../lib/opentelemetry/instrumentation/ruby_kafka/events/consumer/process_message'

describe OpenTelemetry::Instrumentation::RubyKafka::Events::Consumer::ProcessMessage do
  let(:described_class) { OpenTelemetry::Instrumentation::RubyKafka::Events::Consumer::ProcessMessage }
  let(:instrumentation) { OpenTelemetry::Instrumentation::RubyKafka::Instrumentation.instance }
  let(:exporter) { EXPORTER }
  let(:spans) { exporter.finished_spans }
  let(:span) { spans.first }

  let(:group_id) { SecureRandom.uuid }
  let(:topic) { 'my-topic' }
  let(:key) { SecureRandom.hex }
  let(:partition) { rand(0..100) }
  let(:offset) { rand(1..1000) }
  let(:offset_lag) { rand(1..1000) }
  let(:payload) do
    {
      group_id: group_id,
      key: key,
      topic: topic,
      partition: partition,
      offset: offset,
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

    _(span.name).must_equal('kafka.consumer.process_message')
    _(span.start_timestamp).must_be_instance_of(Time)
    _(span.end_timestamp).must_be_instance_of(Time)

    _(span.attributes['messaging.system']).must_equal('kafka')
    _(span.attributes['topic']).must_equal(topic)
    _(span.attributes['message_key']).must_equal(key)
    _(span.attributes['partition']).must_equal(partition)
    _(span.attributes['offset']).must_equal(offset)
    _(span.attributes['offset_lag']).must_equal(offset_lag)
  end
end
