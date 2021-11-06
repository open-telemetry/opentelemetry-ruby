# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

require_relative '../../../../../lib/opentelemetry/instrumentation/ruby_kafka'
require_relative '../../../../../lib/opentelemetry/instrumentation/ruby_kafka/patches/consumer'

describe OpenTelemetry::Instrumentation::RubyKafka::Patches::Consumer do
  let(:instrumentation) { OpenTelemetry::Instrumentation::RubyKafka::Instrumentation.instance }
  let(:exporter) { EXPORTER }
  let(:spans) { exporter.finished_spans }

  let(:host) { ENV.fetch('TEST_KAFKA_HOST') { '127.0.0.1' } }
  let(:port) { (ENV.fetch('TEST_KAFKA_PORT') { 29_092 }) }

  let(:kafka) { Kafka.new(["#{host}:#{port}"], client_id: 'opentelemetry-kafka-test') }
  let(:topic) { "topic-#{SecureRandom.uuid}" }
  let(:producer) { kafka.producer }
  let(:consumer) { kafka.consumer(group_id: SecureRandom.uuid, fetcher_max_queue_size: 1) }

  before do
    kafka.create_topic(topic)
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
    consumer.stop
    kafka.close
  end

  describe '#each_message' do
    it 'traces each_meassage call' do
      kafka.deliver_message('hello', topic: topic)
      kafka.deliver_message('hello2', topic: topic)

      begin
        counter = 0
        consumer.each_message do |_msg|
          counter += 1
          raise 'oops' if counter >= 2
        end
      rescue StandardError # rubocop:disable Lint/HandleExceptions
      end

      process_spans = spans.select { |s| s.name == "#{topic} process" }

      # First pair for send and process spans
      first_process_span = process_spans[0]
      _(first_process_span.name).must_equal("#{topic} process")
      _(first_process_span.kind).must_equal(:consumer)
      _(first_process_span.attributes['messaging.destination']).must_equal(topic)
      _(first_process_span.attributes['messaging.kafka.partition']).must_equal(0)

      first_process_span_link = first_process_span.links[0]
      linked_span_context = first_process_span_link.span_context

      linked_send_span = spans.find { |s| s.span_id == linked_span_context.span_id }
      _(linked_send_span.name).must_equal("#{topic} send")
      _(linked_send_span.trace_id).must_equal(first_process_span.trace_id)
      _(linked_send_span.trace_id).must_equal(linked_span_context.trace_id)

      # Second pair of send and process spans
      second_process_span = process_spans[1]
      _(second_process_span.name).must_equal("#{topic} process")
      _(second_process_span.kind).must_equal(:consumer)

      second_process_span_link = second_process_span.links[0]
      linked_span_context = second_process_span_link.span_context

      linked_send_span = spans.find { |s| s.span_id == linked_span_context.span_id }
      _(linked_send_span.name).must_equal("#{topic} send")
      _(linked_send_span.trace_id).must_equal(second_process_span.trace_id)
      _(linked_send_span.trace_id).must_equal(linked_span_context.trace_id)

      event = second_process_span.events.first
      _(event.name).must_equal('exception')
      _(event.attributes['exception.type']).must_equal('RuntimeError')
      _(event.attributes['exception.message']).must_equal('oops')

      _(spans.size).must_equal(4)
    end
  end

  describe '#each_batch' do
    it 'traces each_batch call' do
      kafka.deliver_message('hello', topic: topic)
      kafka.deliver_message('hello2', topic: topic)

      begin
        consumer.each_batch { |_b| raise 'oops' }
      rescue StandardError # rubocop:disable Lint/HandleExceptions
      end

      span = spans.find { |s| s.name == "#{topic} process" }
      _(span.name).must_equal("#{topic} process")
      _(span.kind).must_equal(:consumer)
      _(span.attributes['messaging.destination']).must_equal(topic)
      _(span.attributes['messaging.kafka.partition']).must_equal(0)
      _(span.attributes['messaging.kafka.message_count']).must_equal(2)

      event = span.events.first
      _(event.name).must_equal('exception')
      _(event.attributes['exception.type']).must_equal('RuntimeError')
      _(event.attributes['exception.message']).must_equal('oops')

      first_link = span.links[0]
      linked_span_context = first_link.span_context
      _(linked_span_context.trace_id).must_equal(spans[0].trace_id)
      _(linked_span_context.span_id).must_equal(spans[0].span_id)

      second_link = span.links[1]
      linked_span_context = second_link.span_context
      _(linked_span_context.trace_id).must_equal(spans[1].trace_id)
      _(linked_span_context.span_id).must_equal(spans[1].span_id)

      _(spans.size).must_equal(3)
    end
  end
end unless ENV['OMIT_SERVICES']
