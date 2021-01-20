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
  let(:url) { ENV.fetch(' RABBITMQ_URL') { 'amqp://guest:guest@rabbitmq:5672' } }
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

    _(spans.size).must_equal(2)
    _(spans[0].name).must_equal("#{topic}.ruby.news send")
    _(spans[0].kind).must_equal(:producer)

    _(spans[1].name).must_equal("#{topic}.ruby.news process")
    _(spans[1].kind).must_equal(:consumer)

    linked_span_context = spans[1].links.first.span_context
    _(linked_span_context.trace_id).must_equal(spans[0].trace_id)
    _(linked_span_context.span_id).must_equal(spans[0].span_id)
  end
end
