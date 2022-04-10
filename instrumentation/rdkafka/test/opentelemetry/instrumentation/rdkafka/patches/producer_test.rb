# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

require_relative '../../../../../lib/opentelemetry/instrumentation/rdkafka'
require_relative '../../../../../lib/opentelemetry/instrumentation/rdkafka/patches/producer'

unless ENV['OMIT_SERVICES']
  describe OpenTelemetry::Instrumentation::Rdkafka::Patches::Producer do
    let(:instrumentation) { OpenTelemetry::Instrumentation::Rdkafka::Instrumentation.instance }
    let(:exporter) { EXPORTER }
    let(:spans) { exporter.finished_spans }

    let(:host) { ENV.fetch('TEST_KAFKA_HOST') { '127.0.0.1' } }
    let(:port) { (ENV.fetch('TEST_KAFKA_PORT') { 29_092 }) }

    before do
      # Clear spans
      exporter.reset

      instrumentation.install
    end

    after do
      # Force re-install of instrumentation
      instrumentation.instance_variable_set(:@installed, false)
    end

    describe 'tracing' do
      it 'traces sync produce calls' do
        topic_name = 'producer-patch-trace'
        config = { "bootstrap.servers": "#{host}:#{port}" }

        producer = Rdkafka::Config.new(config).producer
        delivery_handles = []

        message_name = "msg#{Time.now}"

        delivery_handles << producer.produce(
          topic: topic_name,
          payload: "Payload #{message_name}",
          key: "Key #{message_name}"
        )

        delivery_handles.each(&:wait)

        _(spans.first.name).must_equal("#{topic_name} send")
        _(spans.first.kind).must_equal(:producer)

        _(spans.first.attributes['messaging.system']).must_equal('kafka')
        _(spans.first.attributes['messaging.destination']).must_equal(topic_name)

        producer.close
      end
    end
  end
end
