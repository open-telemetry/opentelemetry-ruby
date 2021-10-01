# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'
require 'securerandom'

require_relative '../../../../../lib/opentelemetry/instrumentation/rdkafka'
require_relative '../../../../../lib/opentelemetry/instrumentation/rdkafka/patches/consumer'

describe OpenTelemetry::Instrumentation::Rdkafka::Patches::Consumer do
  let(:instrumentation) { OpenTelemetry::Instrumentation::Rdkafka::Instrumentation.instance }
  let(:exporter) { EXPORTER }
  let(:spans) { exporter.finished_spans }

  let(:host) { ENV.fetch('TEST_KAFKA_HOST') { '127.0.0.1' } }
  let(:port) { (ENV.fetch('TEST_KAFKA_PORT') { 29_092 }) }

  # let(:kafka) { Kafka.new(["#{host}:#{port}"], client_id: 'opentelemetry-kafka-test') }
  # let(:topic) { "topic-#{SecureRandom.uuid}" }
  # let(:producer) { kafka.producer }
  # let(:consumer) { kafka.consumer(group_id: SecureRandom.uuid, fetcher_max_queue_size: 1) }

  before do
    # Clear spans
    exporter.reset

    instrumentation.install
  end

  after do
    # Force re-install of instrumentation
    instrumentation.instance_variable_set(:@installed, false)
  end

  describe '#each' do
    it 'traces each call' do
      rand_hash = SecureRandom.hex(10)
      topic_name = "consumer-patch-trace-#{rand_hash}"
      config  = { :"bootstrap.servers" => "#{host}:#{port}" }

      producer = Rdkafka::Config.new(config).producer
      delivery_handles = []

      delivery_handles << producer.produce(
        topic:   topic_name,
        payload: "never gonna",
        key:     "Key 1"
      )

      delivery_handles << producer.produce(
        topic:   topic_name,
        payload: "give you up",
        key:     "Key 2"
      )

      delivery_handles.each(&:wait)

      producer.close

      consumer_config = config.merge({
         :"group.id" => "me",
         "auto.offset.reset": 'smallest', # https://stackoverflow.com/a/51081649
      })
      consumer = Rdkafka::Config::new(config.merge(consumer_config)).consumer
      consumer.subscribe(topic_name)

      counter = 0
      begin
        consumer.each do |_msg|
          counter += 1
          raise 'oops' if counter >= 2
        end
      rescue StandardError # rubocop:disable Lint/HandleExceptions
      end

      process_spans = spans.select { |s| s.name == "#{topic_name} process" }

      # First pair for send and process spans
      first_process_span = process_spans[0]
      _(first_process_span.name).must_equal("#{topic_name} process")
      _(first_process_span.kind).must_equal(:consumer)
      _(first_process_span.attributes['messaging.destination']).must_equal(topic_name)
      _(first_process_span.attributes['messaging.kafka.partition']).wont_be_nil


      first_process_span_link = first_process_span.links[0]
      linked_span_context = first_process_span_link.span_context

      linked_send_span = spans.find { |s| s.span_id == linked_span_context.span_id }
      _(linked_send_span.name).must_equal("#{topic_name} send")
      _(linked_send_span.trace_id).must_equal(first_process_span.trace_id)
      _(linked_send_span.trace_id).must_equal(linked_span_context.trace_id)

      # Second pair of send and process spans
      second_process_span = process_spans[1]
      _(second_process_span.name).must_equal("#{topic_name} process")
      _(second_process_span.kind).must_equal(:consumer)

      second_process_span_link = second_process_span.links[0]
      linked_span_context = second_process_span_link.span_context

      linked_send_span = spans.find { |s| s.span_id == linked_span_context.span_id }
      _(linked_send_span.name).must_equal("#{topic_name} send")
      _(linked_send_span.trace_id).must_equal(second_process_span.trace_id)
      _(linked_send_span.trace_id).must_equal(linked_span_context.trace_id)

      event = second_process_span.events.first
      _(event.name).must_equal('exception')
      _(event.attributes['exception.type']).must_equal('RuntimeError')
      _(event.attributes['exception.message']).must_equal('oops')

      _(spans.size).must_equal(4)

      consumer.close
    end
  end

  # describe '#each_batch' do
  #   it 'traces each_batch call' do
  #     kafka.deliver_message('hello', topic: topic)
  #     kafka.deliver_message('hello2', topic: topic)
  #
  #     begin
  #       consumer.each_batch { |_b| raise 'oops' }
  #     rescue StandardError # rubocop:disable Lint/HandleExceptions
  #     end
  #
  #     span = spans.find { |s| s.name == "#{topic} process" }
  #     _(span.name).must_equal("#{topic} process")
  #     _(span.kind).must_equal(:consumer)
  #     _(span.attributes['messaging.destination']).must_equal(topic)
  #     _(span.attributes['messaging.kafka.partition']).must_equal(0)
  #     _(span.attributes['messaging.kafka.message_count']).must_equal(2)
  #
  #     event = span.events.first
  #     _(event.name).must_equal('exception')
  #     _(event.attributes['exception.type']).must_equal('RuntimeError')
  #     _(event.attributes['exception.message']).must_equal('oops')
  #
  #     first_link = span.links[0]
  #     linked_span_context = first_link.span_context
  #     _(linked_span_context.trace_id).must_equal(spans[0].trace_id)
  #     _(linked_span_context.span_id).must_equal(spans[0].span_id)
  #
  #     second_link = span.links[1]
  #     linked_span_context = second_link.span_context
  #     _(linked_span_context.trace_id).must_equal(spans[1].trace_id)
  #     _(linked_span_context.span_id).must_equal(spans[1].span_id)
  #
  #     _(spans.size).must_equal(3)
  #   end
  # end
end unless ENV['OMIT_SERVICES']
