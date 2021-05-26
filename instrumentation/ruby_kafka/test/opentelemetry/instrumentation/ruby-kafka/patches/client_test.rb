# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

require_relative '../../../../../lib/opentelemetry/instrumentation/ruby_kafka'
require_relative '../../../../../lib/opentelemetry/instrumentation/ruby_kafka/patches/client'

describe OpenTelemetry::Instrumentation::RubyKafka::Patches::Client do
  let(:instrumentation) { OpenTelemetry::Instrumentation::RubyKafka::Instrumentation.instance }
  let(:exporter) { EXPORTER }
  let(:spans) { exporter.finished_spans }
  let(:host) { ENV.fetch('TEST_KAFKA_HOST') { '127.0.0.1' } }
  let(:port) { (ENV.fetch('TEST_KAFKA_PORT') { 29_092 }) }
  let(:kafka) { Kafka.new(["#{host}:#{port}"], client_id: 'opentelemetry-kafka-test') }
  let(:topic) { "topic-#{SecureRandom.uuid}" }

  before do
    kafka.create_topic(topic)

    # Clear spans
    exporter.reset

    instrumentation.install
  end

  after do
    # Force re-install of instrumentation
    instrumentation.instance_variable_set(:@installed, false)

    # Clean up
    kafka.close
  end

  it 'traces produce and consuming' do
    kafka.deliver_message('hello', topic: topic)
    kafka.each_message(topic: topic) { |_msg| break }

    _(spans.size).must_equal(2)
    _(spans[0].name).must_equal("#{topic} send")
    _(spans[0].kind).must_equal(:producer)

    _(spans[1].name).must_equal("#{topic} process")
    _(spans[1].kind).must_equal(:consumer)
  end
end unless ENV['OMIT_SERVICES']
