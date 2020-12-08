# frozen_string_literal: true

# Copyright 2020 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

require_relative '../../../../../../lib/opentelemetry/instrumentation/ruby_kafka'
require_relative '../../../../../../lib/opentelemetry/instrumentation/ruby_kafka/events/produce_operation/send_messages'

describe OpenTelemetry::Instrumentation::RubyKafka::Events::ProduceOperation::SendMessages do
  let(:described_class) { OpenTelemetry::Instrumentation::RubyKafka::Events::ProduceOperation::SendMessages }
  let(:instrumentation) { OpenTelemetry::Instrumentation::RubyKafka::Instrumentation.instance }
  let(:exporter) { EXPORTER }
  let(:spans) { exporter.finished_spans }
  let(:span) { spans.first }

  let(:message_count) { rand(10..100) }
  let(:sent_message_count) { rand(1..message_count) }
  let(:payload) do
    {
      message_count: message_count,
      sent_message_count: sent_message_count
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

    _(span.name).must_equal('kafka.producer.send_messages')
    _(span.start_timestamp).must_be_instance_of(Time)
    _(span.end_timestamp).must_be_instance_of(Time)

    _(span.attributes['messaging.system']).must_equal('kafka')
    _(span.attributes['messaging.kafka.message_count']).must_equal(message_count)
    _(span.attributes['messaging.kafka.sent_message_count']).must_equal(sent_message_count)
  end
end
