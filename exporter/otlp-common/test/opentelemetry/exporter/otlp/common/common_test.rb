# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::Exporter::OTLP::Common do
  let(:common) { OpenTelemetry::Exporter::OTLP::Common }

  describe '#as_encoded_etsr' do
    it 'handles valid and empty span data' do
      # Valid span data
      span_data = OpenTelemetry::TestHelpers.create_span_data
      result = common.as_encoded_etsr([span_data])
      _(result).wont_be_nil
      _(result).must_be_kind_of(String)

      # Empty array
      result = common.as_encoded_etsr([])
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
        result = common.as_encoded_etsr([span_data])
        _(log_stream.string).must_match(/ERROR -- : OpenTelemetry error: encoding error for key a/)
        _(result).wont_be_nil

        # StandardError during encoding
        span_data = OpenTelemetry::TestHelpers.create_span_data
        Opentelemetry::Proto::Collector::Trace::V1::ExportTraceServiceRequest.stub(:encode, ->(_) { raise StandardError, 'encoding failed' }) do
          result = common.as_encoded_etsr([span_data])
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
      result = common.as_etsr([span_data])
      _(result).must_be_kind_of(Opentelemetry::Proto::Collector::Trace::V1::ExportTraceServiceRequest)
      _(result.resource_spans).wont_be_empty

      # Empty array
      result = common.as_etsr([])
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

      etsr = common.as_etsr([span_data1, span_data2, span_data3])
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

      etsr = common.as_etsr([span_data1, span_data2, span_data3])
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

      encoded_etsr = common.as_encoded_etsr([root, client, server_span, consumer_span, span].map(&:to_span_data))

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
                  scope: Opentelemetry::Proto::Common::V1::InstrumentationScope.new(name: 'tracer', version: 'v0.0.1'),
                  spans: [
                    Opentelemetry::Proto::Trace::V1::Span.new(
                      trace_id: trace_id, span_id: root_span_id, parent_span_id: nil, name: 'root',
                      kind: Opentelemetry::Proto::Trace::V1::Span::SpanKind::SPAN_KIND_INTERNAL,
                      start_time_unix_nano: (start_timestamp.to_r * 1_000_000_000).to_i,
                      end_time_unix_nano: (end_timestamp.to_r * 1_000_000_000).to_i,
                      status: Opentelemetry::Proto::Trace::V1::Status.new(
                        code: Opentelemetry::Proto::Trace::V1::Status::StatusCode::STATUS_CODE_OK
                      ),
                      flags: (
                        Opentelemetry::Proto::Trace::V1::SpanFlags::SPAN_FLAGS_CONTEXT_HAS_IS_REMOTE_MASK |
                        1
                      )
                    ),
                    Opentelemetry::Proto::Trace::V1::Span.new(
                      trace_id: trace_id, span_id: client_span_id, parent_span_id: child_span_id, name: 'client',
                      kind: Opentelemetry::Proto::Trace::V1::Span::SpanKind::SPAN_KIND_CLIENT,
                      start_time_unix_nano: ((start_timestamp + 2).to_r * 1_000_000_000).to_i,
                      end_time_unix_nano: (end_timestamp.to_r * 1_000_000_000).to_i,
                      status: Opentelemetry::Proto::Trace::V1::Status.new(
                        code: Opentelemetry::Proto::Trace::V1::Status::StatusCode::STATUS_CODE_UNSET
                      ),
                      flags: (
                        Opentelemetry::Proto::Trace::V1::SpanFlags::SPAN_FLAGS_CONTEXT_HAS_IS_REMOTE_MASK |
                        1
                      )
                    ),
                    Opentelemetry::Proto::Trace::V1::Span.new(
                      trace_id: trace_id, span_id: consumer_span_id, parent_span_id: child_span_id, name: 'consumer',
                      kind: Opentelemetry::Proto::Trace::V1::Span::SpanKind::SPAN_KIND_CONSUMER,
                      start_time_unix_nano: ((start_timestamp + 5).to_r * 1_000_000_000).to_i,
                      end_time_unix_nano: (end_timestamp.to_r * 1_000_000_000).to_i,
                      status: Opentelemetry::Proto::Trace::V1::Status.new(
                        code: Opentelemetry::Proto::Trace::V1::Status::StatusCode::STATUS_CODE_UNSET
                      ),
                      flags: (
                        Opentelemetry::Proto::Trace::V1::SpanFlags::SPAN_FLAGS_CONTEXT_HAS_IS_REMOTE_MASK |
                        1
                      )
                    ),
                    Opentelemetry::Proto::Trace::V1::Span.new(
                      trace_id: trace_id, span_id: child_span_id, parent_span_id: root_span_id, name: 'child',
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
                          attributes: [Opentelemetry::Proto::Common::V1::KeyValue.new(key: 'attr', value: Opentelemetry::Proto::Common::V1::AnyValue.new(int_value: 42))]
                        )
                      ],
                      links: [
                        Opentelemetry::Proto::Trace::V1::Span::Link.new(
                          trace_id: trace_id,
                          span_id: root_span_id,
                          attributes: [
                            Opentelemetry::Proto::Common::V1::KeyValue.new(key: 'attr', value: Opentelemetry::Proto::Common::V1::AnyValue.new(int_value: 4))
                          ],
                          flags: (
                            Opentelemetry::Proto::Trace::V1::SpanFlags::SPAN_FLAGS_CONTEXT_HAS_IS_REMOTE_MASK |
                            1
                          )
                        )
                      ],
                      status: Opentelemetry::Proto::Trace::V1::Status.new(
                        code: Opentelemetry::Proto::Trace::V1::Status::StatusCode::STATUS_CODE_ERROR
                      ),
                      flags: (
                        Opentelemetry::Proto::Trace::V1::SpanFlags::SPAN_FLAGS_CONTEXT_HAS_IS_REMOTE_MASK |
                        1
                      )
                    )
                  ]
                ),
                Opentelemetry::Proto::Trace::V1::ScopeSpans.new(
                  scope: Opentelemetry::Proto::Common::V1::InstrumentationScope.new(name: 'other_tracer'),
                  spans: [
                    Opentelemetry::Proto::Trace::V1::Span.new(
                      trace_id: trace_id, span_id: server_span_id, parent_span_id: client_span_id, name: 'server',
                      kind: Opentelemetry::Proto::Trace::V1::Span::SpanKind::SPAN_KIND_SERVER,
                      start_time_unix_nano: ((start_timestamp + 3).to_r * 1_000_000_000).to_i,
                      end_time_unix_nano: (end_timestamp.to_r * 1_000_000_000).to_i,
                      status: Opentelemetry::Proto::Trace::V1::Status.new(
                        code: Opentelemetry::Proto::Trace::V1::Status::StatusCode::STATUS_CODE_UNSET
                      ),
                      flags: (
                        Opentelemetry::Proto::Trace::V1::SpanFlags::SPAN_FLAGS_CONTEXT_HAS_IS_REMOTE_MASK |
                        1
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

  describe 'private methods' do
    describe '#as_otlp_span' do
      it 'converts span data with all features' do
        span_data = OpenTelemetry::TestHelpers.create_span_data(
          name: 'test-span', kind: :client,
          total_recorded_attributes: 1, attributes: { 'key' => 'value' }
        )
        result = common.send(:as_otlp_span, span_data)
        _(result).must_be_kind_of(Opentelemetry::Proto::Trace::V1::Span)
        _(result.name).must_equal('test-span')
        _(result.kind).must_equal(:SPAN_KIND_CLIENT)
        _(result.trace_state).must_be_kind_of(String)
      end

      it 'handles parent_span_id, status, and nil collections' do
        # INVALID_SPAN_ID
        span_data = OpenTelemetry::TestHelpers.create_span_data(parent_span_id: OpenTelemetry::Trace::INVALID_SPAN_ID)
        result = common.send(:as_otlp_span, span_data)
        _(result.parent_span_id).must_be_empty

        # Valid parent_span_id
        parent_id = OpenTelemetry::Trace.generate_span_id
        span_data = OpenTelemetry::TestHelpers.create_span_data(parent_span_id: parent_id)
        result = common.send(:as_otlp_span, span_data)
        _(result.parent_span_id).must_equal(parent_id)

        # Nil status
        span_data = OpenTelemetry::TestHelpers.create_span_data(status: nil)
        result = common.send(:as_otlp_span, span_data)
        _(result.status).must_be_nil

        # Status with description
        status = OpenTelemetry::Trace::Status.error('Something went wrong')
        span_data = OpenTelemetry::TestHelpers.create_span_data(status: status)
        result = common.send(:as_otlp_span, span_data)
        _(result.status.code).must_equal(:STATUS_CODE_ERROR)
        _(result.status.message).must_equal('Something went wrong')

        # Nil collections
        span_data = OpenTelemetry::TestHelpers.create_span_data(attributes: nil, events: nil, links: nil)
        result = common.send(:as_otlp_span, span_data)
        _(result.attributes).must_be_empty
        _(result.events).must_be_empty
        _(result.links).must_be_empty
        _(result.dropped_attributes_count).must_equal(0)
        _(result.dropped_events_count).must_equal(0)
        _(result.dropped_links_count).must_equal(0)
      end

      it 'calculates dropped counts and converts events/links' do
        # Dropped counts
        span_data = OpenTelemetry::TestHelpers.create_span_data(total_recorded_attributes: 10, attributes: { 'a' => 1, 'b' => 2 })
        result = common.send(:as_otlp_span, span_data)
        _(result.dropped_attributes_count).must_equal(8)

        event = OpenTelemetry::SDK::Trace::Event.new(name: 'event1', timestamp: Time.now.to_i * 1_000_000_000)
        span_data = OpenTelemetry::TestHelpers.create_span_data(total_recorded_events: 5, events: [event])
        result = common.send(:as_otlp_span, span_data)
        _(result.dropped_events_count).must_equal(4)

        trace_id = OpenTelemetry::Trace.generate_trace_id
        span_id = OpenTelemetry::Trace.generate_span_id
        span_context = OpenTelemetry::Trace::SpanContext.new(trace_id: trace_id, span_id: span_id)
        link = OpenTelemetry::Trace::Link.new(span_context)
        span_data = OpenTelemetry::TestHelpers.create_span_data(total_recorded_links: 3, links: [link])
        result = common.send(:as_otlp_span, span_data)
        _(result.dropped_links_count).must_equal(2)

        # Events with attributes
        event = OpenTelemetry::SDK::Trace::Event.new(name: 'test-event', attributes: { 'event_key' => 'event_value' }, timestamp: Time.now.to_i * 1_000_000_000)
        span_data = OpenTelemetry::TestHelpers.create_span_data(total_recorded_events: 1, events: [event])
        result = common.send(:as_otlp_span, span_data)
        _(result.events.length).must_equal(1)
        _(result.events.first.name).must_equal('test-event')
        _(result.events.first.attributes.length).must_equal(1)

        # Links with attributes
        link = OpenTelemetry::Trace::Link.new(span_context, { 'link_key' => 'link_value' })
        span_data = OpenTelemetry::TestHelpers.create_span_data(total_recorded_links: 1, links: [link])
        result = common.send(:as_otlp_span, span_data)
        _(result.links.length).must_equal(1)
        _(result.links.first.trace_id).must_equal(trace_id)
        _(result.links.first.span_id).must_equal(span_id)
        _(result.links.first.attributes.length).must_equal(1)
        _(result.links.first.trace_state).must_be_kind_of(String)
      end
    end

    describe '#as_otlp_status_code' do
      it 'converts status codes correctly' do
        _(common.send(:as_otlp_status_code, OpenTelemetry::Trace::Status::OK)).must_equal(Opentelemetry::Proto::Trace::V1::Status::StatusCode::STATUS_CODE_OK)
        _(common.send(:as_otlp_status_code, OpenTelemetry::Trace::Status::ERROR)).must_equal(Opentelemetry::Proto::Trace::V1::Status::StatusCode::STATUS_CODE_ERROR)
        _(common.send(:as_otlp_status_code, 999)).must_equal(Opentelemetry::Proto::Trace::V1::Status::StatusCode::STATUS_CODE_UNSET)
        _(common.send(:as_otlp_status_code, nil)).must_equal(Opentelemetry::Proto::Trace::V1::Status::StatusCode::STATUS_CODE_UNSET)
      end
    end

    describe '#as_otlp_span_kind' do
      it 'converts span kinds correctly' do
        _(common.send(:as_otlp_span_kind, :internal)).must_equal(Opentelemetry::Proto::Trace::V1::Span::SpanKind::SPAN_KIND_INTERNAL)
        _(common.send(:as_otlp_span_kind, :server)).must_equal(Opentelemetry::Proto::Trace::V1::Span::SpanKind::SPAN_KIND_SERVER)
        _(common.send(:as_otlp_span_kind, :client)).must_equal(Opentelemetry::Proto::Trace::V1::Span::SpanKind::SPAN_KIND_CLIENT)
        _(common.send(:as_otlp_span_kind, :producer)).must_equal(Opentelemetry::Proto::Trace::V1::Span::SpanKind::SPAN_KIND_PRODUCER)
        _(common.send(:as_otlp_span_kind, :consumer)).must_equal(Opentelemetry::Proto::Trace::V1::Span::SpanKind::SPAN_KIND_CONSUMER)
        _(common.send(:as_otlp_span_kind, :unknown)).must_equal(Opentelemetry::Proto::Trace::V1::Span::SpanKind::SPAN_KIND_UNSPECIFIED)
        _(common.send(:as_otlp_span_kind, nil)).must_equal(Opentelemetry::Proto::Trace::V1::Span::SpanKind::SPAN_KIND_UNSPECIFIED)
      end
    end

    describe '#as_otlp_key_value' do
      it 'converts various data types' do
        result = common.send(:as_otlp_key_value, 'key', 'value')
        _(result).must_be_kind_of(Opentelemetry::Proto::Common::V1::KeyValue)
        _(result.key).must_equal('key')
        _(result.value.string_value).must_equal('value')

        result = common.send(:as_otlp_key_value, 'count', 42)
        _(result.value.int_value).must_equal(42)

        result = common.send(:as_otlp_key_value, 'ratio', 3.14)
        _(result.value.double_value).must_equal(3.14)

        result = common.send(:as_otlp_key_value, 'flag', true)
        _(result.value.bool_value).must_equal(true)

        result = common.send(:as_otlp_key_value, 'flag', false)
        _(result.value.bool_value).must_equal(false)

        result = common.send(:as_otlp_key_value, 'items', [1, 2, 3])
        _(result.value.array_value).wont_be_nil
        _(result.value.array_value.values.length).must_equal(3)
      end

      it 'handles encoding errors gracefully' do
        OpenTelemetry::TestHelpers.with_test_logger do |log_stream|
          invalid_value = (+"\xC2").force_encoding(::Encoding::ASCII_8BIT)
          result = common.send(:as_otlp_key_value, 'bad_key', invalid_value)
          _(result.key).must_equal('bad_key')
          _(result.value.string_value).must_equal('Encoding Error')
          _(log_stream.string).must_match(/encoding error for key bad_key/)
        end
      end
    end

    describe '#as_otlp_any_value' do
      it 'converts all value types correctly' do
        # Strings
        _(common.send(:as_otlp_any_value, 'test').string_value).must_equal('test')
        _(common.send(:as_otlp_any_value, '').string_value).must_equal('')

        # Integers
        _(common.send(:as_otlp_any_value, 123).int_value).must_equal(123)
        _(common.send(:as_otlp_any_value, -456).int_value).must_equal(-456)
        _(common.send(:as_otlp_any_value, 0).int_value).must_equal(0)

        # Floats
        _(common.send(:as_otlp_any_value, 1.23).double_value).must_equal(1.23)
        _(common.send(:as_otlp_any_value, -4.56).double_value).must_equal(-4.56)

        # Booleans
        _(common.send(:as_otlp_any_value, true).bool_value).must_equal(true)
        _(common.send(:as_otlp_any_value, false).bool_value).must_equal(false)

        # Arrays
        result = common.send(:as_otlp_any_value, [1, 'two', 3.0])
        _(result.array_value.values.length).must_equal(3)
        _(result.array_value.values[0].int_value).must_equal(1)
        _(result.array_value.values[1].string_value).must_equal('two')
        _(result.array_value.values[2].double_value).must_equal(3.0)

        # Nested arrays
        result = common.send(:as_otlp_any_value, [[1, 2], [3, 4]])
        _(result.array_value.values.length).must_equal(2)
        _(result.array_value.values[0].array_value.values[0].int_value).must_equal(1)

        # Empty array
        _(common.send(:as_otlp_any_value, []).array_value.values).must_be_empty

        # Unsupported types
        result = common.send(:as_otlp_any_value, { key: 'value' })
        _(result).must_be_kind_of(Opentelemetry::Proto::Common::V1::AnyValue)
        _(result.string_value).must_be_empty

        result = common.send(:as_otlp_any_value, nil)
        _(result).must_be_kind_of(Opentelemetry::Proto::Common::V1::AnyValue)
      end
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

      etsr = common.as_etsr([span.to_span_data])

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

      etsr = common.as_etsr(spans)
      _(etsr.resource_spans.length).must_equal(2)
      _(etsr.resource_spans[0].scope_spans.length).must_equal(2)
      _(etsr.resource_spans[1].scope_spans.length).must_equal(2)

      # Test resource attributes preservation
      resource = OpenTelemetry::SDK::Resources::Resource.create(
        'service.name' => 'my-service', 'service.version' => '1.2.3', 'deployment.environment' => 'production'
      )
      span_data = OpenTelemetry::TestHelpers.create_span_data(resource: resource)
      etsr = common.as_etsr([span_data])

      resource_attrs = etsr.resource_spans.first.resource.attributes
      _(resource_attrs.length).must_equal(3)
      attr_map = resource_attrs.each_with_object({}) { |kv, hash| hash[kv.key] = kv.value.string_value }
      _(attr_map['service.name']).must_equal('my-service')
      _(attr_map['service.version']).must_equal('1.2.3')
      _(attr_map['deployment.environment']).must_equal('production')

      # Test scope without version
      scope = OpenTelemetry::SDK::InstrumentationScope.new('test-scope', nil)
      span_data = OpenTelemetry::TestHelpers.create_span_data(instrumentation_scope: scope)
      etsr = common.as_etsr([span_data])
      _(etsr.resource_spans.first.scope_spans.first.scope.name).must_equal('test-scope')
      _(etsr.resource_spans.first.scope_spans.first.scope.version).must_be_empty
    end
  end
end
