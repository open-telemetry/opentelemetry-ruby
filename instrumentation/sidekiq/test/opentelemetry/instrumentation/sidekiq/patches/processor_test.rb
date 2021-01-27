# # frozen_string_literal: true

# # Copyright The OpenTelemetry Authors
# #
# # SPDX-License-Identifier: Apache-2.0

# require 'test_helper'

# require 'opentelemetry-instrumentation-redis'
# require 'fakeredis/minitest'

# require_relative '../../../../../lib/opentelemetry/instrumentation/sidekiq'
# require_relative '../../../../../lib/opentelemetry/instrumentation/sidekiq/patches/processor'

# class SidekiqAdapterTest
#   def perform; end
# end

# describe OpenTelemetry::Instrumentation::Sidekiq::Patches::Processor do
#   let(:instrumentation) { OpenTelemetry::Instrumentation::Sidekiq::Instrumentation.instance }
#   let(:redis_instrumentation) { OpenTelemetry::Instrumentation::Redis::Instrumentation.instance }
#   let(:exporter) { EXPORTER }
#   let(:spans) { exporter.finished_spans }
#   let(:span) { spans.first }
#   let(:config) { {} }
#   let(:manager) { Minitest::Mock.new }
#   let(:processor) do
#     if ::Sidekiq::VERSION.match?(/^6\.1/)
#       ::Sidekiq::Processor.new(manager, ::Sidekiq.options)
#     else
#       ::Sidekiq::Processor.new(manager)
#     end
#   end

#   before do
#     manager.expect(:options, { queues: ['default'] })
#     manager.expect(:options, { queues: ['default'] })
#     manager.expect(:options, { queues: ['default'] })

#     # Clear spans
#     exporter.reset
#     redis_instrumentation.install
#     instrumentation.install(config)
#   end

#   after do
#     # Force re-install of instrumentation
#     redis_instrumentation.instance_variable_set(:@installed, false)
#     instrumentation.instance_variable_set(:@installed, false)
#   end

#   describe '#process_one' do
#     it 'does not trace' do
#       processor.process_one
#       _(spans.size).must_equal(0)
#     end

#     describe 'when process_one tracing is enabled' do
#       let(:config) { { trace_processor_process_one: true } }

#       it 'traces' do
#         processor.process_one
#         span_names = spans.map(&:name)
#         _(span_names).must_include('Sidekiq::Processor#process_one')
#         _(span_names).must_include('BRPOP')
#       end
#     end
#   end
# end
