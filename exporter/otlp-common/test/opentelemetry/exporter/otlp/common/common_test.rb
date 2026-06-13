# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::Exporter::OTLP::Common do
  describe '#as_encoded_etsr' do
    it 'handles valid and empty span data' do
      # Valid span data
      span_data = OpenTelemetry::TestHelpers.create_span_data
      result = OpenTelemetry::Exporter::OTLP::Common.as_encoded_etsr([span_data])
      _(result).wont_be_nil
      _(result).must_be_kind_of(String)

      # Empty array
      result = OpenTelemetry::Exporter::OTLP::Common.as_encoded_etsr([])
      _(result).wont_be_nil
      _(result).must_be_kind_of(String)
    end

    it 'handles encoding errors gracefully' do
      OpenTelemetry::TestHelpers.with_test_logger do |log_stream|
        # Encoding error in attributes
        span_data = OpenTelemetry::TestHelpers.create_span_data(
          total_recorded_attributes: 1,
          attributes: { 'a' => (+"\xC2").force_encoding(::Encoding::ASCII_8BIT) }
        )

        result = OpenTelemetry::Exporter::OTLP::Common.as_encoded_etsr([span_data])

        _(log_stream.string).must_match(
          /ERROR -- : OpenTelemetry error: encoding error for key a and value �/
        )
        _(result).wont_be_nil

        # StandardError during encoding
        span_data = OpenTelemetry::TestHelpers.create_span_data
        Opentelemetry::Proto::Collector::Trace::V1::ExportTraceServiceRequest.stub(:encode, ->(_) { raise StandardError, 'encoding failed' }) do
          result = OpenTelemetry::Exporter::OTLP::Common.as_encoded_etsr([span_data])
          _(result).must_be_nil
          _(log_stream.string).must_match(/ERROR -- : OpenTelemetry error: unexpected error in OTLP::Common#as_encoded_etsr/)
        end
      end
    end
  end

  describe '#as_etsr' do
    it 'handles valid and empty span data' do
      # Valid span data
      span_data = OpenTelemetry::TestHelpers.create_span_data
      result = OpenTelemetry::Exporter::OTLP::Common.as_etsr([span_data])
      _(result).must_be_kind_of(Opentelemetry::Proto::Collector::Trace::V1::ExportTraceServiceRequest)
      _(result.resource_spans).wont_be_empty

      # Empty array
      result = OpenTelemetry::Exporter::OTLP::Common.as_etsr([])
      _(result).must_be_kind_of(Opentelemetry::Proto::Collector::Trace::V1::ExportTraceServiceRequest)
      _(result.resource_spans).must_be_empty
    end

    it 'batches per resource and instrumentation scope' do
      # Test resource batching
      resource_one = OpenTelemetry::SDK::Resources::Resource.create('k1' => 'v1')
      resource_two = OpenTelemetry::SDK::Resources::Resource.create('k2' => 'v2')
      span_data1 = OpenTelemetry::TestHelpers.create_span_data(resource: resource_one)
      span_data2 = OpenTelemetry::TestHelpers.create_span_data(resource: resource_two)
      span_data3 = OpenTelemetry::TestHelpers.create_span_data(resource: resource_two)

      etsr = OpenTelemetry::Exporter::OTLP::Common.as_etsr([span_data1, span_data2, span_data3])

      _(etsr.resource_spans.length).must_equal(2)
      _(etsr.resource_spans[0].scope_spans[0].spans.length).must_equal(1)
      _(etsr.resource_spans[1].scope_spans[0].spans.length).must_equal(2)

      # Test scope batching
      resource = OpenTelemetry::SDK::Resources::Resource.create('service.name' => 'test')
      scope1 = OpenTelemetry::SDK::InstrumentationScope.new('scope1', '1.0.0')
      scope2 = OpenTelemetry::SDK::InstrumentationScope.new('scope2', '2.0.0')
      span_data1 = OpenTelemetry::TestHelpers.create_span_data(resource: resource, instrumentation_scope: scope1)
      span_data2 = OpenTelemetry::TestHelpers.create_span_data(resource: resource, instrumentation_scope: scope2)
      span_data3 = OpenTelemetry::TestHelpers.create_span_data(resource: resource, instrumentation_scope: scope1)

      etsr = OpenTelemetry::Exporter::OTLP::Common.as_etsr([span_data1, span_data2, span_data3])
      _(etsr.resource_spans.length).must_equal(1)
      _(etsr.resource_spans[0].scope_spans.length).must_equal(2)
    end

    it 'translates all the things' do
      OpenTelemetry.tracer_provider = OpenTelemetry::SDK::Trace::TracerProvider.new(resource: OpenTelemetry::SDK::Resources::Resource.telemetry_sdk)
      tracer = OpenTelemetry.tracer_provider.tracer('tracer', 'v0.0.1')
      other_tracer = OpenTelemetry.tracer_provider.tracer('other_tracer')

      trace_id = OpenTelemetry::Trace.generate_trace_id
      root_span_id = OpenTelemetry::Trace.generate_span_id
      child_span_id = OpenTelemetry::Trace.generate_span_id
      client_span_id = OpenTelemetry::Trace.generate_span_id
      server_span_id = OpenTelemetry::Trace.generate_span_id
      consumer_span_id = OpenTelemetry::Trace.generate_span_id
      start_timestamp = Time.now
      end_timestamp = start_timestamp + 6

      root = OpenTelemetry::TestHelpers.with_ids(trace_id, root_span_id) { tracer.start_root_span('root', kind: :internal, start_timestamp: start_timestamp) }
      root.status = OpenTelemetry::Trace::Status.ok
      root.finish(end_timestamp: end_timestamp)
      root_ctx = OpenTelemetry::Trace.context_with_span(root)

      span = OpenTelemetry::TestHelpers.with_ids(trace_id, child_span_id) { tracer.start_span('child', with_parent: root_ctx, kind: :producer, start_timestamp: start_timestamp + 1, links: [OpenTelemetry::Trace::Link.new(root.context, 'attr' => 4)]) }
      span['b'] = true
      span['f'] = 1.1
      span['i'] = 2
      span['s'] = 'val'
      span['a'] = [3, 4]
      span.status = OpenTelemetry::Trace::Status.error
      child_ctx = OpenTelemetry::Trace.context_with_span(span)

      client = OpenTelemetry::TestHelpers.with_ids(trace_id, client_span_id) { tracer.start_span('client', with_parent: child_ctx, kind: :client, start_timestamp: start_timestamp + 2).finish(end_timestamp: end_timestamp) }
      client_ctx = OpenTelemetry::Trace.context_with_span(client)

      server_span = OpenTelemetry::TestHelpers.with_ids(trace_id, server_span_id) { other_tracer.start_span('server', with_parent: client_ctx, kind: :server, start_timestamp: start_timestamp + 3).finish(end_timestamp: end_timestamp) }
      span.add_event('event', attributes: { 'attr' => 42 }, timestamp: start_timestamp + 4)
      consumer_span = OpenTelemetry::TestHelpers.with_ids(trace_id, consumer_span_id) { tracer.start_span('consumer', with_parent: child_ctx, kind: :consumer, start_timestamp: start_timestamp + 5).finish(end_timestamp: end_timestamp) }
      span.finish(end_timestamp: end_timestamp)

      # Ordered by the first finished
      encoded_etsr = OpenTelemetry::Exporter::OTLP::Common.as_encoded_etsr(
        [
          root,
          client,
          server_span,
          consumer_span,
          span
        ].map(&:to_span_data)
      )

      expected_encoded_etsr = Opentelemetry::Proto::Collector::Trace::V1::ExportTraceServiceRequest.encode(
        Opentelemetry::Proto::Collector::Trace::V1::ExportTraceServiceRequest.new(
          resource_spans: [
            Opentelemetry::Proto::Trace::V1::ResourceSpans.new(
              resource: Opentelemetry::Proto::Resource::V1::Resource.new(
                attributes: [
                  Opentelemetry::Proto::Common::V1::KeyValue.new(key: 'telemetry.sdk.name', value: Opentelemetry::Proto::Common::V1::AnyValue.new(string_value: 'opentelemetry')),
                  Opentelemetry::Proto::Common::V1::KeyValue.new(key: 'telemetry.sdk.language', value: Opentelemetry::Proto::Common::V1::AnyValue.new(string_value: 'ruby')),
                  Opentelemetry::Proto::Common::V1::KeyValue.new(key: 'telemetry.sdk.version', value: Opentelemetry::Proto::Common::V1::AnyValue.new(string_value: OpenTelemetry::SDK::VERSION))
                ]
              ),
              scope_spans: [
                Opentelemetry::Proto::Trace::V1::ScopeSpans.new(
                  scope: Opentelemetry::Proto::Common::V1::InstrumentationScope.new(
                    name: 'tracer',
                    version: 'v0.0.1'
                  ),
                  spans: [
                    Opentelemetry::Proto::Trace::V1::Span.new(
                      trace_id: trace_id,
                      span_id: root_span_id,
                      parent_span_id: nil,
                      name: 'root',
                      kind: Opentelemetry::Proto::Trace::V1::Span::SpanKind::SPAN_KIND_INTERNAL,
                      start_time_unix_nano: (start_timestamp.to_r * 1_000_000_000).to_i,
                      end_time_unix_nano: (end_timestamp.to_r * 1_000_000_000).to_i,
                      status: Opentelemetry::Proto::Trace::V1::Status.new(
                        code: Opentelemetry::Proto::Trace::V1::Status::StatusCode::STATUS_CODE_OK
                      )
                    ),
                    Opentelemetry::Proto::Trace::V1::Span.new(
                      trace_id: trace_id,
                      span_id: client_span_id,
                      parent_span_id: child_span_id,
                      name: 'client',
                      kind: Opentelemetry::Proto::Trace::V1::Span::SpanKind::SPAN_KIND_CLIENT,
                      start_time_unix_nano: ((start_timestamp + 2).to_r * 1_000_000_000).to_i,
                      end_time_unix_nano: (end_timestamp.to_r * 1_000_000_000).to_i,
                      status: Opentelemetry::Proto::Trace::V1::Status.new(
                        code: Opentelemetry::Proto::Trace::V1::Status::StatusCode::STATUS_CODE_UNSET
                      )
                    ),
                    Opentelemetry::Proto::Trace::V1::Span.new(
                      trace_id: trace_id,
                      span_id: consumer_span_id,
                      parent_span_id: child_span_id,
                      name: 'consumer',
                      kind: Opentelemetry::Proto::Trace::V1::Span::SpanKind::SPAN_KIND_CONSUMER,
                      start_time_unix_nano: ((start_timestamp + 5).to_r * 1_000_000_000).to_i,
                      end_time_unix_nano: (end_timestamp.to_r * 1_000_000_000).to_i,
                      status: Opentelemetry::Proto::Trace::V1::Status.new(
                        code: Opentelemetry::Proto::Trace::V1::Status::StatusCode::STATUS_CODE_UNSET
                      )
                    ),
                    Opentelemetry::Proto::Trace::V1::Span.new(
                      trace_id: trace_id,
                      span_id: child_span_id,
                      parent_span_id: root_span_id,
                      name: 'child',
                      kind: Opentelemetry::Proto::Trace::V1::Span::SpanKind::SPAN_KIND_PRODUCER,
                      start_time_unix_nano: ((start_timestamp + 1).to_r * 1_000_000_000).to_i,
                      end_time_unix_nano: (end_timestamp.to_r * 1_000_000_000).to_i,
                      attributes: [
                        Opentelemetry::Proto::Common::V1::KeyValue.new(key: 'b', value: Opentelemetry::Proto::Common::V1::AnyValue.new(bool_value: true)),
                        Opentelemetry::Proto::Common::V1::KeyValue.new(key: 'f', value: Opentelemetry::Proto::Common::V1::AnyValue.new(double_value: 1.1)),
                        Opentelemetry::Proto::Common::V1::KeyValue.new(key: 'i', value: Opentelemetry::Proto::Common::V1::AnyValue.new(int_value: 2)),
                        Opentelemetry::Proto::Common::V1::KeyValue.new(key: 's', value: Opentelemetry::Proto::Common::V1::AnyValue.new(string_value: 'val')),
                        Opentelemetry::Proto::Common::V1::KeyValue.new(
                          key: 'a',
                          value: Opentelemetry::Proto::Common::V1::AnyValue.new(
                            array_value: Opentelemetry::Proto::Common::V1::ArrayValue.new(
                              values: [
                                Opentelemetry::Proto::Common::V1::AnyValue.new(int_value: 3),
                                Opentelemetry::Proto::Common::V1::AnyValue.new(int_value: 4)
                              ]
                            )
                          )
                        )
                      ],
                      events: [
                        Opentelemetry::Proto::Trace::V1::Span::Event.new(
                          time_unix_nano: ((start_timestamp + 4).to_r * 1_000_000_000).to_i,
                          name: 'event',
                          attributes: [
                            Opentelemetry::Proto::Common::V1::KeyValue.new(key: 'attr', value: Opentelemetry::Proto::Common::V1::AnyValue.new(int_value: 42))
                          ]
                        )
                      ],
                      links: [
                        Opentelemetry::Proto::Trace::V1::Span::Link.new(
                          trace_id: trace_id,
                          span_id: root_span_id,
                          attributes: [
                            Opentelemetry::Proto::Common::V1::KeyValue.new(key: 'attr', value: Opentelemetry::Proto::Common::V1::AnyValue.new(int_value: 4))
                          ]
                        )
                      ],
                      status: Opentelemetry::Proto::Trace::V1::Status.new(
                        code: Opentelemetry::Proto::Trace::V1::Status::StatusCode::STATUS_CODE_ERROR
                      )
                    )
                  ]
                ),
                Opentelemetry::Proto::Trace::V1::ScopeSpans.new(
                  scope: Opentelemetry::Proto::Common::V1::InstrumentationScope.new(
                    name: 'other_tracer'
                  ),
                  spans: [
                    Opentelemetry::Proto::Trace::V1::Span.new(
                      trace_id: trace_id,
                      span_id: server_span_id,
                      parent_span_id: client_span_id,
                      name: 'server',
                      kind: Opentelemetry::Proto::Trace::V1::Span::SpanKind::SPAN_KIND_SERVER,
                      start_time_unix_nano: ((start_timestamp + 3).to_r * 1_000_000_000).to_i,
                      end_time_unix_nano: (end_timestamp.to_r * 1_000_000_000).to_i,
                      status: Opentelemetry::Proto::Trace::V1::Status.new(
                        code: Opentelemetry::Proto::Trace::V1::Status::StatusCode::STATUS_CODE_UNSET
                      )
                    )
                  ]
                )
              ]
            )
          ]
        )
      )

      _(encoded_etsr).must_equal(expected_encoded_etsr)
    end
  end

  describe 'integration tests' do
    it 'handles complex spans with all features' do
      OpenTelemetry.tracer_provider = OpenTelemetry::SDK::Trace::TracerProvider.new(
        resource: OpenTelemetry::SDK::Resources::Resource.create('service.name' => 'test-service', 'service.version' => '1.0.0')
      )

      tracer = OpenTelemetry.tracer_provider.tracer('test-tracer', '1.0.0')
      trace_id = OpenTelemetry::Trace.generate_trace_id
      span_id = OpenTelemetry::Trace.generate_span_id

      span = OpenTelemetry::TestHelpers.with_ids(trace_id, span_id) { tracer.start_root_span('complex-span', kind: :server) }
      span['string_attr'] = 'value'
      span['int_attr'] = 42
      span['float_attr'] = 3.14
      span['bool_attr'] = true
      span['array_attr'] = [1, 2, 3]
      span.add_event('event1', attributes: { 'event_attr' => 'event_value' })
      span.add_event('event2')
      span.status = OpenTelemetry::Trace::Status.error('Test error')
      span.finish

      etsr = OpenTelemetry::Exporter::OTLP::Common.as_etsr([span.to_span_data])

      _(etsr.resource_spans.length).must_equal(1)
      _(etsr.resource_spans.first.resource.attributes.length).must_equal(2)
      _(etsr.resource_spans.first.scope_spans.first.scope.name).must_equal('test-tracer')
      _(etsr.resource_spans.first.scope_spans.first.scope.version).must_equal('1.0.0')

      otlp_span = etsr.resource_spans.first.scope_spans.first.spans.first
      _(otlp_span.name).must_equal('complex-span')
      _(otlp_span.kind).must_equal(:SPAN_KIND_SERVER)
      _(otlp_span.attributes.length).must_equal(5)
      _(otlp_span.events.length).must_equal(2)
      _(otlp_span.status.code).must_equal(:STATUS_CODE_ERROR)
      _(otlp_span.status.message).must_equal('Test error')
    end

    it 'handles multiple resources, scopes, and attributes' do
      resource1 = OpenTelemetry::SDK::Resources::Resource.create('service' => 'service1')
      resource2 = OpenTelemetry::SDK::Resources::Resource.create('service' => 'service2')
      scope1 = OpenTelemetry::SDK::InstrumentationScope.new('scope1', '1.0')
      scope2 = OpenTelemetry::SDK::InstrumentationScope.new('scope2', '2.0')

      spans = [
        OpenTelemetry::TestHelpers.create_span_data(resource: resource1, instrumentation_scope: scope1),
        OpenTelemetry::TestHelpers.create_span_data(resource: resource1, instrumentation_scope: scope2),
        OpenTelemetry::TestHelpers.create_span_data(resource: resource2, instrumentation_scope: scope1),
        OpenTelemetry::TestHelpers.create_span_data(resource: resource2, instrumentation_scope: scope2)
      ]

      etsr = OpenTelemetry::Exporter::OTLP::Common.as_etsr(spans)
      _(etsr.resource_spans.length).must_equal(2)
      _(etsr.resource_spans[0].scope_spans.length).must_equal(2)
      _(etsr.resource_spans[1].scope_spans.length).must_equal(2)

      # Test resource attributes preservation
      resource = OpenTelemetry::SDK::Resources::Resource.create(
        'service.name' => 'my-service', 'service.version' => '1.2.3', 'deployment.environment' => 'production'
      )
      span_data = OpenTelemetry::TestHelpers.create_span_data(resource: resource)
      etsr = OpenTelemetry::Exporter::OTLP::Common.as_etsr([span_data])

      resource_attrs = etsr.resource_spans.first.resource.attributes
      _(resource_attrs.length).must_equal(3)
      attr_map = resource_attrs.each_with_object({}) { |kv, hash| hash[kv.key] = kv.value.string_value }
      _(attr_map['service.name']).must_equal('my-service')
      _(attr_map['service.version']).must_equal('1.2.3')
      _(attr_map['deployment.environment']).must_equal('production')

      # Test scope without version
      scope = OpenTelemetry::SDK::InstrumentationScope.new('test-scope', nil)
      span_data = OpenTelemetry::TestHelpers.create_span_data(instrumentation_scope: scope)
      etsr = OpenTelemetry::Exporter::OTLP::Common.as_etsr([span_data])
      _(etsr.resource_spans.first.scope_spans.first.scope.name).must_equal('test-scope')
      _(etsr.resource_spans.first.scope_spans.first.scope.version).must_be_empty
    end
  end
end
