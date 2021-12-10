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

  it 'encodes message keys' do
    invalid_utf8_key = String.new("\xAF\x0F\xEF", encoding: 'ASCII-8BIT')
    kafka.deliver_message('hello', key: invalid_utf8_key, topic: topic)
    kafka.deliver_message('hello2', key: 'foobarbaz', topic: topic)
    begin
      counter = 0
      kafka.each_message(topic: topic) do |_msg|
        counter += 1
        break if counter >= 2
      end
    end

    send_spans = spans.select { |s| s.name == "#{topic} send" }
    _(send_spans[0].attributes).wont_include('messaging.kafka.message_key')
    _(send_spans[1].attributes['messaging.kafka.message_key']).must_equal('foobarbaz')

    process_spans = spans.select { |s| s.name == "#{topic} process" }
    _(process_spans[0].attributes).wont_include('messaging.kafka.message_key')
    _(process_spans[1].attributes['messaging.kafka.message_key']).must_equal('foobarbaz')
  end
end unless ENV['OMIT_SERVICES']
