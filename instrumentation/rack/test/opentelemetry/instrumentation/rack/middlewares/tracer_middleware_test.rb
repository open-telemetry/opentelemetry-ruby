# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

# require Instrumentation so .install method is found:
require_relative '../../../../../lib/opentelemetry/instrumentation/rack'
require_relative '../../../../../lib/opentelemetry/instrumentation/rack/instrumentation'
require_relative '../../../../../lib/opentelemetry/instrumentation/rack/middlewares/tracer_middleware'

describe OpenTelemetry::Instrumentation::Rack::Middlewares::TracerMiddleware do
  let(:instrumentation_module) { OpenTelemetry::Instrumentation::Rack }
  let(:instrumentation_class) { instrumentation_module::Instrumentation }
  let(:instrumentation) { instrumentation_class.instance }

  let(:described_class) { OpenTelemetry::Instrumentation::Rack::Middlewares::TracerMiddleware }

  let(:app) { ->(_env) { [200, { 'Content-Type' => 'text/plain' }, ['OK']] } }
  let(:middleware) { described_class.new(app) }
  let(:rack_builder) { Rack::Builder.new }

  let(:exporter) { EXPORTER }
  let(:finished_spans) { exporter.finished_spans }
  let(:first_span) { exporter.finished_spans.first }

  let(:default_config) { {} }
  let(:config) { default_config }
  let(:env) { {} }
  let(:uri) { '/' }

  before do
    # clear captured spans:
    exporter.reset

    # simulate a fresh install:
    instrumentation.instance_variable_set('@installed', false)
    instrumentation.install(config)

    # clear out cached config:
    described_class.send(:clear_cached_config)

    # integrate tracer middleware:
    rack_builder.run app
    rack_builder.use described_class
  end

  after do
    # installation is 'global', so it should be reset:
    instrumentation.instance_variable_set('@installed', false)
    instrumentation.install(default_config)
  end

  describe '#call' do
    before do
      Rack::MockRequest.new(rack_builder).get(uri, env)
    end

    it 'records attributes' do
      _(first_span.attributes['http.method']).must_equal 'GET'
      _(first_span.attributes['http.status_code']).must_equal 200
      _(first_span.attributes['http.target']).must_equal '/'
      _(first_span.attributes['http.url']).must_be_nil
      _(first_span.name).must_equal 'HTTP GET'
      _(first_span.kind).must_equal :server
    end

    it 'does not explicitly set status OK' do
      _(first_span.status.code).must_equal OpenTelemetry::Trace::Status::UNSET
    end

    it 'has no parent' do
      _(first_span.parent_span_id).must_equal OpenTelemetry::Trace::INVALID_SPAN_ID
    end

    describe 'when a query is passed in' do
      let(:uri) { '/endpoint?query=true' }

      it 'records the query path' do
        _(first_span.attributes['http.target']).must_equal '/endpoint?query=true'
        _(first_span.name).must_equal 'HTTP GET'
      end
    end

    describe 'config[:untraced_endpoints]' do
      describe 'when an array is passed in' do
        let(:config) { { untraced_endpoints: ['/ping'] } }

        it 'does not trace paths listed in the array' do
          Rack::MockRequest.new(rack_builder).get('/ping', env)

          ping_span = finished_spans.find { |s| s.attributes['http.target'] == '/ping' }
          _(ping_span).must_be_nil

          root_span = finished_spans.find { |s| s.attributes['http.target'] == '/' }
          _(root_span).wont_be_nil
        end
      end

      describe 'when a string is passed in' do
        let(:config) { { untraced_endpoints: '/ping' } }

        it 'traces everything' do
          Rack::MockRequest.new(rack_builder).get('/ping', env)

          ping_span = finished_spans.find { |s| s.attributes['http.target'] == '/ping' }
          _(ping_span).wont_be_nil

          root_span = finished_spans.find { |s| s.attributes['http.target'] == '/' }
          _(root_span).wont_be_nil
        end
      end

      describe 'when nil is passed in' do
        let(:config) { { untraced_endpoints: nil } }

        it 'traces everything' do
          Rack::MockRequest.new(rack_builder).get('/ping', env)

          ping_span = finished_spans.find { |s| s.attributes['http.target'] == '/ping' }
          _(ping_span).wont_be_nil

          root_span = finished_spans.find { |s| s.attributes['http.target'] == '/' }
          _(root_span).wont_be_nil
        end
      end
    end

    describe 'config[:untraced_requests]' do
      describe 'when a callable is passed in' do
        let(:untraced_callable) do
          ->(env) { env['PATH_INFO'] =~ %r{^\/assets} }
        end
        let(:config) { default_config.merge(untraced_requests: untraced_callable) }

        it 'does not trace requests in which the callable returns true' do
          Rack::MockRequest.new(rack_builder).get('/assets', env)

          ping_span = finished_spans.find { |s| s.attributes['http.target'] == '/assets' }
          _(ping_span).must_be_nil

          root_span = finished_spans.find { |s| s.attributes['http.target'] == '/' }
          _(root_span).wont_be_nil
        end
      end

      describe 'when nil is passed in' do
        let(:config) { { untraced_requests: nil } }

        it 'traces everything' do
          Rack::MockRequest.new(rack_builder).get('/assets', env)

          ping_span = finished_spans.find { |s| s.attributes['http.target'] == '/assets' }
          _(ping_span).wont_be_nil

          root_span = finished_spans.find { |s| s.attributes['http.target'] == '/' }
          _(root_span).wont_be_nil
        end
      end
    end

    describe 'config[:allowed_request_headers]' do
      let(:env) do
        Hash(
          'CONTENT_LENGTH' => '123',
          'CONTENT_TYPE' => 'application/json',
          'HTTP_FOO_BAR' => 'http foo bar value'
        )
      end

      it 'defaults to nil' do
        _(first_span.attributes['http.request.headers.foo_bar']).must_be_nil
      end

      describe 'when configured' do
        let(:config) { default_config.merge(allowed_request_headers: ['foo_BAR']) }

        it 'returns attribute' do
          _(first_span.attributes['http.request.headers.foo_bar']).must_equal 'http foo bar value'
        end
      end

      describe 'when content-type' do
        let(:config) { default_config.merge(allowed_request_headers: ['CONTENT_TYPE']) }

        it 'returns attribute' do
          _(first_span.attributes['http.request.headers.content_type']).must_equal 'application/json'
        end
      end

      describe 'when content-length' do
        let(:config) { default_config.merge(allowed_request_headers: ['CONTENT_LENGTH']) }

        it 'returns attribute' do
          _(first_span.attributes['http.request.headers.content_length']).must_equal '123'
        end
      end
    end

    describe 'config[:allowed_response_headers]' do
      let(:app) do
        ->(_env) { [200, { 'Foo-Bar' => 'foo bar response header' }, ['OK']] }
      end

      it 'defaults to nil' do
        _(first_span.attributes['http.response.headers.foo_bar']).must_be_nil
      end

      describe 'when configured' do
        let(:config) { default_config.merge(allowed_response_headers: ['Foo-Bar']) }

        it 'returns attribute' do
          _(first_span.attributes['http.response.headers.foo_bar']).must_equal 'foo bar response header'
        end

        describe 'case-sensitively' do
          let(:config) { default_config.merge(allowed_response_headers: ['fOO-bAR']) }

          it 'returns attribute' do
            _(first_span.attributes['http.response.headers.foo_bar']).must_equal 'foo bar response header'
          end
        end
      end
    end

    describe 'config[:record_frontend_span]' do
      let(:request_span) { exporter.finished_spans.first }

      describe 'default' do
        it 'does not record span' do
          _(exporter.finished_spans.size).must_equal 1
        end

        it 'does not parent the request_span' do
          _(request_span.parent_span_id).must_equal OpenTelemetry::Trace::INVALID_SPAN_ID
        end
      end

      describe 'when recordable' do
        let(:config) { default_config.merge(record_frontend_span: true) }
        let(:env) { Hash('HTTP_X_REQUEST_START' => Time.now.to_i) }
        let(:frontend_span) { exporter.finished_spans[1] }
        let(:request_span) { exporter.finished_spans[0] }

        it 'records span' do
          _(exporter.finished_spans.size).must_equal 2
          _(frontend_span.name).must_equal 'http_server.proxy'
          _(frontend_span.attributes['service']).must_be_nil
        end

        it 'changes request_span kind' do
          _(request_span.kind).must_equal :internal
        end

        it 'frontend_span parents request_span' do
          _(request_span.parent_span_id).must_equal frontend_span.span_id
        end
      end
    end
  end

  describe 'config[:quantization]' do
    before do
      Rack::MockRequest.new(rack_builder).get('/really_long_url', env)
    end

    describe 'without quantization' do
      it 'span.name defaults to low cardinality name HTTP method' do
        _(first_span.name).must_equal 'HTTP GET'
        _(first_span.attributes['http.target']).must_equal '/really_long_url'
      end
    end

    describe 'with simple quantization' do
      let(:quantization_example) do
        ->(url, _env) { url.to_s }
      end

      let(:config) { default_config.merge(url_quantization: quantization_example) }

      it 'sets the span.name to the full path' do
        _(first_span.name).must_equal '/really_long_url'
        _(first_span.attributes['http.target']).must_equal '/really_long_url'
      end
    end

    describe 'with quantization' do
      let(:quantization_example) do
        # demonstrate simple shortening of URL:
        ->(url, _env) { url.to_s[0..5] }
      end
      let(:config) { default_config.merge(url_quantization: quantization_example) }

      it 'mutates url according to url_quantization' do
        _(first_span.name).must_equal '/reall'
      end
    end
  end

  describe '#call with error' do
    SimulatedError = Class.new(StandardError)

    let(:app) do
      ->(_env) { raise SimulatedError }
    end

    it 'records error in span and then re-raises' do
      assert_raises SimulatedError do
        Rack::MockRequest.new(rack_builder).get('/', env)
      end
      _(first_span.status.code).must_equal OpenTelemetry::Trace::Status::ERROR
    end
  end
end
