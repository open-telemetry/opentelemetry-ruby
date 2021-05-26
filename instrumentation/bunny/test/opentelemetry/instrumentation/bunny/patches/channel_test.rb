# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

require_relative '../../../../../lib/opentelemetry/instrumentation/bunny'
require_relative '../../../../../lib/opentelemetry/instrumentation/bunny/patch_helpers'
require_relative '../../../../../lib/opentelemetry/instrumentation/bunny/patches/channel'

describe OpenTelemetry::Instrumentation::Bunny::Patches::Channel do
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

    exchange.publish('San Diego update', routing_key: 'ruby.news')

    queue.pop { |_msg| break }

    _(spans.size >= 3).must_equal(true)

    send_span = spans.find { |span| span.name == "#{topic}.ruby.news send" }
    _(send_span).wont_be_nil
    _(send_span.kind).must_equal(:producer)
    _(send_span.attributes['messaging.system']).must_equal('rabbitmq')
    _(send_span.attributes['messaging.destination']).must_equal(topic)
    _(send_span.attributes['messaging.destination_kind']).must_equal('topic')
    _(send_span.attributes['messaging.protocol']).must_equal('AMQP')
    _(send_span.attributes['messaging.protocol_version']).must_equal('0.9.1')
    _(send_span.attributes['messaging.rabbitmq.routing_key']).must_equal('ruby.news')
    _(send_span.attributes['net.peer.name']).must_equal(host)
    _(send_span.attributes['net.peer.port']).must_equal(port.to_i)

    receive_span = spans.find { |span| span.name == "#{topic}.ruby.news receive" }
    _(receive_span).wont_be_nil
    _(receive_span.kind).must_equal(:consumer)
    _(receive_span.attributes['messaging.system']).must_equal('rabbitmq')
    _(receive_span.attributes['messaging.destination']).must_equal(topic)
    _(receive_span.attributes['messaging.destination_kind']).must_equal('topic')
    _(receive_span.attributes['messaging.protocol']).must_equal('AMQP')
    _(receive_span.attributes['messaging.protocol_version']).must_equal('0.9.1')
    _(receive_span.attributes['messaging.rabbitmq.routing_key']).must_equal('ruby.news')
    _(receive_span.attributes['net.peer.name']).must_equal(host)
    _(receive_span.attributes['net.peer.port']).must_equal(port.to_i)

    process_span = spans.find { |span| span.name == "#{topic}.ruby.news process" }
    _(process_span).wont_be_nil
    _(process_span.kind).must_equal(:consumer)
    _(process_span.trace_id).must_equal(receive_span.trace_id)

    linked_span_context = process_span.links.first.span_context
    _(linked_span_context.trace_id).must_equal(send_span.trace_id)
    _(linked_span_context.span_id).must_equal(send_span.span_id)
  end
end unless ENV['OMIT_SERVICES']
