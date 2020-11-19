# frozen_string_literal: true

# Copyright 2020 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

require_relative '../../../../lib/opentelemetry/instrumentation/ruby_kafka'

describe OpenTelemetry::Instrumentation::RubyKafka::Instrumentation do
  let(:instrumentation) { OpenTelemetry::Instrumentation::RubyKafka::Instrumentation.instance }
  let(:exporter) { EXPORTER }
  let(:spans) { exporter.finished_spans }

  let(:host) { ENV.fetch('TEST_KAFKA_HOST') { '127.0.0.1' } }
  let(:port) { (ENV.fetch('TEST_KAFKA_PORT') { 29_092 }) }

  let(:kafka) { Kafka.new(["#{host}:#{port}"], client_id: 'opentelemetry-kafka-test') }
  let(:topic) { "topic-#{SecureRandom.uuid}" }
  let(:async_topic) { "async-#{topic}" }
  let(:producer) { kafka.producer }
  let(:consumer) { kafka.consumer(group_id: SecureRandom.uuid, fetcher_max_queue_size: 1) }
  let(:async_producer) { kafka.async_producer(delivery_threshold: 1000) }

  before do
    kafka.create_topic(topic)
    kafka.create_topic(async_topic)
    consumer.subscribe(topic)

    # Clear spans
    exporter.reset

    instrumentation.install
  end

  after do
    # Force re-install of instrumentation
    instrumentation.instance_variable_set(:@installed, false)

    # Clean up
    producer.shutdown
    async_producer.shutdown
    consumer.stop
    kafka.close
    clear_notification_subscriptions
  end

  describe 'tracing' do
    it 'traces client deliver_message call' do
      kafka.deliver_message('hello', topic: topic)
      span = spans.find { |s| s.name == 'send' }
      _(span.name).must_equal('send')
      _(span.kind).must_equal(:producer)
    end

    it 'traces a client each_meassage call' do
      kafka.deliver_message('hello', topic: topic)
      consumer.each_message { |msg| puts msg.value; break; }
      span = spans.find { |s| s.name == 'process' }
      _(span.name).must_equal('process')
      _(span.kind).must_equal(:consumer)
    end

    it 'traces sync produce calls' do
      producer.produce('hello', topic: topic)
      producer.deliver_messages

      _(spans.first.name).must_equal('send')
      _(spans.first.kind).must_equal(:producer)

      _(spans.first.attributes['messaging.system']).must_equal('kafka')
      _(spans.first.attributes['messaging.destination']).must_equal(topic)

      _(spans.last.name).must_equal('kafka.producer.deliver_messages')
      _(spans.last.kind).must_equal(:client)

      _(spans.last.attributes['messaging.system']).must_equal('kafka')
      _(spans.last.attributes['message_count']).must_equal(1)
      _(spans.last.attributes['delivered_message_count']).must_equal(1)
      _(spans.last.attributes['attempts']).must_equal(1)
    end

    it 'traces async produce calls' do
      async_producer.produce('hello async', topic: async_topic)
      producer.deliver_messages

      # Wait for the async calls to produce spans
      wait_for(error_message: 'Max wait time exceeded for async producer') { EXPORTER.finished_spans.size.positive? }

      _(spans.first.name).must_equal('send')
      _(spans.first.kind).must_equal(:producer)

      _(spans.first.attributes['messaging.system']).must_equal('kafka')
      _(spans.first.attributes['messaging.destination']).must_equal(async_topic)
    end
  end

  private

  def wait_for(max_attempts: 10, retry_delay: 0.10, error_message:)
    attempts = 0
    while attempts < max_attempts
      return if yield

      attempts += 1
      raise error_message if attempts >= max_attempts

      sleep retry_delay
    end
  end
end
