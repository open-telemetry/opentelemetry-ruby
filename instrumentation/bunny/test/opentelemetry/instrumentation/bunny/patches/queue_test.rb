# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

require_relative '../../../../../lib/opentelemetry/instrumentation/bunny'
require_relative '../../../../../lib/opentelemetry/instrumentation/bunny/patch_helpers'
require_relative '../../../../../lib/opentelemetry/instrumentation/bunny/patches/queue'

describe OpenTelemetry::Instrumentation::Bunny::Patches::Queue do
  let(:instrumentation) { OpenTelemetry::Instrumentation::Bunny::Instrumentation.instance }
  let(:exporter) { EXPORTER }
  let(:spans) { exporter.finished_spans }

  let(:url) { ENV.fetch(' RABBITMQ_URL') { 'amqp://guest:guest@rabbitmq:5672' } }
  let(:bunny) { Bunny.new(url) }
  let(:topic) { "topic-#{SecureRandom.uuid}" }
  let(:channel) { bunny.create_channel }
  let(:queue_name) { "opentelemetry-ruby-#{SecureRandom.uuid}" }
  let(:queue) { channel.queue(queue_name) }

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

  describe 'pop' do
    it 'traces messages handled in a block' do
      queue.publish('Hello, opentelemetry!')

      queue.pop { |_delivery_info, _metadata, _payload| break }

      _(spans.last.name).must_equal(".#{queue_name} process")
      _(spans.last.kind).must_equal(:consumer)

      linked_span_context = spans.last.links.first.span_context
      _(linked_span_context.trace_id).must_equal(spans[0].trace_id)
    end

    it 'traces messages returned' do
      queue.publish('Hello, opentelemetry!')

      queue.pop

      _(spans.last.name).must_equal(".#{queue_name} receive")
    end
  end
end
