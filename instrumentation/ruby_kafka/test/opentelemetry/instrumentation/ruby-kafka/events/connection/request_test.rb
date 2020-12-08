# frozen_string_literal: true

# Copyright 2020 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

require_relative '../../../../../../lib/opentelemetry/instrumentation/ruby_kafka'
require_relative '../../../../../../lib/opentelemetry/instrumentation/ruby_kafka/events/connection/request'

describe OpenTelemetry::Instrumentation::RubyKafka::Events::Connection::Request do
  let(:described_class) { OpenTelemetry::Instrumentation::RubyKafka::Events::Connection::Request }
  let(:instrumentation) { OpenTelemetry::Instrumentation::RubyKafka::Instrumentation.instance }
  let(:exporter) { EXPORTER }
  let(:spans) { exporter.finished_spans }
  let(:span) { spans.first }
  let(:api) { 'api' }
  let(:request_size) { rand(1..1000) }
  let(:response_size) { rand(1..1000) }
  let(:payload) do
    {
      request_size: request_size,
      response_size: response_size
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

    _(span.name).must_equal('kafka.connection.request')
    _(span.start_timestamp).must_be_instance_of(Time)
    _(span.end_timestamp).must_be_instance_of(Time)

    _(span.attributes['messaging.system']).must_equal('kafka')
    _(span.attributes['messaging.kafka.request_size']).must_equal(request_size)
    _(span.attributes['messaging.kafka.response_size']).must_equal(response_size)
  end
end
