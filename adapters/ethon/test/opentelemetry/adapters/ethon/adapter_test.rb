# frozen_string_literal: true

# Copyright 2020 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

require_relative '../../../../lib/opentelemetry/adapters/ethon'
require_relative '../../../../lib/opentelemetry/adapters/ethon/patches/easy'

describe OpenTelemetry::Adapters::Ethon::Adapter do
  let(:adapter) { OpenTelemetry::Adapters::Ethon::Adapter.instance }
  let(:exporter) { EXPORTER }
  let(:span) { exporter.finished_spans.first }

  before do
    exporter.reset

    # this is currently a noop but this will future proof the test
    @orig_propagator = OpenTelemetry.propagation.http
    propagator = OpenTelemetry::Context::Propagation::Propagator.new(
      OpenTelemetry::Trace::Propagation::TraceContext.text_injector,
      OpenTelemetry::Trace::Propagation::TraceContext.text_extractor
    )
    OpenTelemetry.propagation.http = propagator
  end

  after do
    # Force re-install of instrumentation
    adapter.instance_variable_set(:@installed, false)

    OpenTelemetry.propagation.http = @orig_propagator
  end

  describe 'tracing' do
    before do
      adapter.install
    end

    it 'before request' do
      _(exporter.finished_spans.size).must_equal 0
    end

    describe 'easy' do
      let(:easy) { ::Ethon::Easy.new(url: 'http://example.com/test') }

      describe '#http_request' do
        it 'preserves HTTP request method on easy instance' do
          easy.http_request('example.com', 'POST')
          _(easy.instance_eval { @otel_method }).must_equal 'POST'
        end
      end

      describe '#headers=' do
        it 'preserves HTTP headers on easy instance' do
          easy.headers = { key: 'value' }
          _(easy.instance_eval { @otel_original_headers }).must_equal(
            key: 'value'
          )
        end
      end

      describe '#perform' do
        let(:span) { easy.instance_eval { @otel_span } }

        it 'creates a span' do
          ::Ethon::Curl.stub(:easy_perform, 0) do
            # Note: suppress call to #complete to isolate #perform functionality
            easy.stub(:complete, nil) do
              easy.perform

              _(span.name).must_equal 'HTTP N/A'
              _(span.attributes['http.method']).must_equal 'N/A'
              _(span.attributes['http.status_code']).must_be_nil
              _(span.attributes['http.url']).must_equal 'http://example.com/test'
            end
          end
        end
      end

      describe '#complete' do
        def stub_response(options)
          easy.stub(:mirror, ::Ethon::Easy::Mirror.new(options)) do
            easy.otel_before_request
            # Note: perform calls complete
            easy.complete

            yield
          end
        end

        it 'when response is successful' do
          stub_response(response_code: 200) do
            _(span.name).must_equal 'HTTP N/A'
            _(span.attributes['http.method']).must_equal 'N/A'
            _(span.attributes['http.status_code']).must_equal 200
            _(span.attributes['http.url']).must_equal 'http://example.com/test'
            _(easy.instance_eval { @otel_span }).must_be_nil
            _(
              easy.instance_eval { @otel_original_headers['traceparent'] }
            ).must_equal "00-#{span.trace_id.unpack1('H*')}-#{span.span_id.unpack1('H*')}-01"
          end
        end

        it 'when response is not successful' do
          stub_response(response_code: 500) do
            _(span.name).must_equal 'HTTP N/A'
            _(span.attributes['http.method']).must_equal 'N/A'
            _(span.attributes['http.status_code']).must_equal 500
            _(span.attributes['http.url']).must_equal 'http://example.com/test'
            _(easy.instance_eval { @otel_span }).must_be_nil
            _(
              easy.instance_eval { @otel_original_headers['traceparent'] }
            ).must_equal "00-#{span.trace_id.unpack1('H*')}-#{span.span_id.unpack1('H*')}-01"
          end
        end

        it 'when request times out' do
          stub_response(response_code: 0, return_code: :operation_timedout) do
            _(span.name).must_equal 'HTTP N/A'
            _(span.attributes['http.method']).must_equal 'N/A'
            _(span.attributes['http.status_code']).must_be_nil
            _(span.attributes['http.url']).must_equal 'http://example.com/test'
            _(span.status.canonical_code).must_equal(
              OpenTelemetry::Trace::Status::UNKNOWN_ERROR
            )
            _(span.status.description).must_equal(
              'Request has failed: Timeout was reached'
            )
            _(easy.instance_eval { @otel_span }).must_be_nil
            _(
              easy.instance_eval { @otel_original_headers['traceparent'] }
            ).must_equal "00-#{span.trace_id.unpack1('H*')}-#{span.span_id.unpack1('H*')}-01"
          end
        end
      end

      describe '#reset' do
        describe 'with headers set up' do
          before do
            easy.headers = { key: 'value' }
          end

          it 'cleans up @otel_original_headers' do
            _(easy.instance_eval { @otel_original_headers }).must_equal(
              key: 'value'
            )

            easy.reset

            _(easy.instance_eval { @otel_original_headers }).must_be_nil
          end
        end

        describe 'with HTTP method set up' do
          before do
            easy.http_request('example.com', :put)
          end

          it 'cleans up @otel_method' do
            _(easy.instance_eval { @otel_method }).must_equal 'PUT'

            easy.reset

            _(easy.instance_eval { @otel_method }).must_be_nil
          end
        end

        describe 'with span initialized' do
          before do
            easy.otel_before_request
          end

          it 'cleans up @otel_span' do
            _(easy.instance_eval { @otel_span }).must_be_instance_of(
              OpenTelemetry::SDK::Trace::Span
            )

            easy.reset

            _(easy.instance_eval { @otel_span }).must_be_nil
          end
        end
      end
    end

    describe 'multi' do
      let(:easy) { ::Ethon::Easy.new }
      let(:multi) { ::Ethon::Multi.new }

      describe '#perform' do
        describe 'with no easy added to multi' do
          it 'does not trace' do
            multi.perform

            _(exporter.finished_spans.size).must_equal 0
          end
        end

        describe 'with easy added to multi' do
          before { multi.add(easy) }

          it 'creates a span' do
            multi.perform

            _(exporter.finished_spans.size).must_equal 1
          end
        end

        describe 'with multiple calls to perform' do
          it 'does not create extra calls to perform without new easies' do
            expect do
              multi.add(easy)
              multi.perform
              multi.perform

              _(exporter.finished_spans.size).must_equal 1
            end
          end

          it 'creates extra traces for each extra valid call to perform' do
            multi.add(easy)
            multi.perform
            multi.add(easy)
            multi.perform

            _(exporter.finished_spans.size).must_equal 2
          end
        end
      end
    end
  end
end
