# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

require_relative '../../../../../lib/opentelemetry/instrumentation/bunny'
require_relative '../../../../../lib/opentelemetry/instrumentation/bunny/patch_helpers'
require_relative '../../../../../lib/opentelemetry/instrumentation/bunny/patches/consumer'

describe OpenTelemetry::Instrumentation::Bunny::Patches::Consumer do
  let(:instrumentation) { OpenTelemetry::Instrumentation::Bunny::Instrumentation.instance }
  let(:exporter) { EXPORTER }
  let(:spans) { exporter.finished_spans }
  let(:host) { ENV.fetch('TEST_RABBITMQ_HOST') { 'localhost' } }
  let(:port) { ENV.fetch('TEST_RABBITMQ_PORT') { '5672' } }
  let(:url) { ENV.fetch('TEST_RABBITMQ_URL') { "amqp://guest:guest@#{host}:#{port}" } }
  let(:bunny) { Bunny.new(url) }
  let(:topic) { "topic-#{SecureRandom.uuid}" }
  let(:channel) { bunny.create_channel }
  let(:exchange) { channel.topic(topic, auto_delete: true) }

  before do
    bunny.start

    # Clear spans
    exporter.reset

    instrumentation.install
  end

  after do
    # Force re-install of instrumentation
    instrumentation.instance_variable_set(:@installed, false)

    # Clean up
    bunny.close
  end

  it 'traces produce and consuming' do
    queue = channel.queue('', exclusive: true).bind(exchange, routing_key: 'ruby.#')

    consumer = queue.subscribe(manual_ack: true) { |_delivery_info, _properties, _payload| }

    exchange.publish('San Diego update', routing_key: 'ruby.news')

    # Wait until the publish message reached the consumer
    sleep 1.0

    consumer.cancel

    _(spans.size >= 3).must_equal(true)

    send_span = spans.find { |span| span.name == "#{topic}.ruby.news send" }
    _(send_span).wont_be_nil
    _(send_span.kind).must_equal(:producer)

    receive_span = spans.find { |span| span.name == "#{topic}.ruby.news receive" }
    _(receive_span).wont_be_nil
    _(receive_span.name).must_equal("#{topic}.ruby.news receive")
    _(receive_span.kind).must_equal(:consumer)

    process_span = spans.find { |span| span.name == "#{topic}.ruby.news process" }
    _(process_span).wont_be_nil
    _(process_span.kind).must_equal(:consumer)
    _(process_span.trace_id).must_equal(receive_span.trace_id)

    linked_span_context = process_span.links.first.span_context
    _(linked_span_context.trace_id).must_equal(send_span.trace_id)
    _(linked_span_context.span_id).must_equal(send_span.span_id)
  end
end unless ENV['OMIT_SERVICES']
