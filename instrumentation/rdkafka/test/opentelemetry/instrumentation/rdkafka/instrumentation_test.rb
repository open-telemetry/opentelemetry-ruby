# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

require_relative '../../../../lib/opentelemetry/instrumentation/rdkafka'

describe OpenTelemetry::Instrumentation::Rdkafka do
  let(:instrumentation) { OpenTelemetry::Instrumentation::Rdkafka::Instrumentation.instance }

  # it 'goes' do
  #   config = {:"bootstrap.servers" => "shopify-tracing.railgun:9092"}
  #   producer = Rdkafka::Config.new(config).producer
  #   delivery_handles = []
  #
  #   i=1
  #   puts "Producing message #{i}"
  #   delivery_handles << producer.produce(
  #     topic:   "ruby-test-topic",
  #     payload: "Payload #{i}",
  #     key:     "Key #{i}"
  #   )
  #
  #   delivery_handles.each(&:wait)
  #
  #   config = {
  #     :"bootstrap.servers" => "shopify-tracing.railgun:9092",
  #     :"group.id" => "ruby-test"
  #   }
  #
  #   consumer = Rdkafka::Config.new(config).consumer
  #   consumer.subscribe("ruby-test-topic")
  #   consumer.each do |message|
  #     puts "Message received: #{message}"
  #   end
  #
  # end

  it 'creates a span for when a message is produced' do
    topic_name = "ruby-test-topic4"
    config  = { :"bootstrap.servers" => "shopify-tracing.railgun:9092" }

    producer = Rdkafka::Config.new(config).producer
    delivery_handles = []

    puts "Producing messages..."

    message_name = "msg#{Time.now}"

    delivery_handles << producer.produce(
      topic:   topic_name,
      payload: "Payload #{message_name}",
      key:     "Key #{message_name}"
    )

    delivery_handles.each(&:wait)

    puts 'Configuring consumer...'
    consumer_config = config.merge({
      :"group.id" => "ruby-test",
      "auto.offset.reset": 'smallest' # https://stackoverflow.com/a/51081649
    })
    consumer = Rdkafka::Config.new(consumer_config).consumer
    consumer.subscribe(topic_name)

    puts 'Consuming messages...'

    consumer.each do |message|
      puts "Message received: #{message}"
      break
    end

    puts " --- "
    puts "num spans: #{EXPORTER.finished_spans.length}"
    puts EXPORTER.finished_spans.first
    puts " --- "

  end

  it 'has #name' do
    _(instrumentation.name).must_equal 'OpenTelemetry::Instrumentation::Rdkafka'
  end

  it 'has #version' do
    _(instrumentation.version).wont_be_nil
    _(instrumentation.version).wont_be_empty
  end

  describe '#install' do
    it 'accepts argument' do
      _(instrumentation.install({})).must_equal(true)
      instrumentation.instance_variable_set(:@installed, false)
    end
  end
end
