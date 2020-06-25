# frozen_string_literal: true

# Copyright 2020 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

# require Adapter so .install method is found:
require_relative '../../../../../lib/opentelemetry/adapters/rack'
require_relative '../../../../../lib/opentelemetry/adapters/rack/adapter'
require_relative '../../../../../lib/opentelemetry/adapters/rack/middlewares/tracer_middleware'

describe OpenTelemetry::Adapters::Rack::Middlewares::TracerMiddleware do
  let(:adapter_module) { OpenTelemetry::Adapters::Rack }
  let(:adapter_class) { adapter_module::Adapter }
  let(:adapter) { adapter_class.instance }

  let(:described_class) { OpenTelemetry::Adapters::Rack::Middlewares::TracerMiddleware }

  let(:app) { ->(_env) { [200, { 'Content-Type' => 'text/plain' }, ['OK']] } }
  let(:middleware) { described_class.new(app) }
  let(:rack_builder) { Rack::Builder.new }

  let(:exporter) { EXPORTER }
  let(:first_span) { exporter.finished_spans.first }

  let(:default_config) { {} }
  let(:config) { default_config }
  let(:env) { {} }

  before do
    # clear captured spans:
    exporter.reset

    # simulate a fresh install:
    adapter.instance_variable_set('@installed', false)
    adapter.install(config)

    # clear out cached config:
    described_class.send(:clear_cached_config)

    # integrate tracer middleware:
    rack_builder.run app
    rack_builder.use described_class
  end

  after do
    # installation is 'global', so it should be reset:
    adapter.instance_variable_set('@installed', false)
    adapter.install(default_config)
  end

  describe '#call' do
    before do
      Rack::MockRequest.new(rack_builder).get('/', env)
    end

    it 'records attributes' do
      _(first_span.attributes['http.method']).must_equal 'GET'
      _(first_span.attributes['http.status_code']).must_equal 200
      _(first_span.attributes['http.status_text']).must_equal 'OK'
      _(first_span.attributes['http.target']).must_equal '/'
      _(first_span.status.canonical_code).must_equal OpenTelemetry::Trace::Status::OK
      _(first_span.attributes['http.url']).must_be_nil
      _(first_span.name).must_equal '/'
      _(first_span.kind).must_equal :server
    end

    it 'has no parent' do
      _(first_span.parent_span_id).must_equal OpenTelemetry::Trace::INVALID_SPAN_ID
    end

    describe 'config[:allowed_request_headers]' do
      let(:env) { Hash('HTTP_FOO_BAR' => 'http foo bar value') }

      it 'defaults to nil' do
        _(first_span.attributes['http.request.headers.foo_bar']).must_be_nil
      end

      describe 'when configured' do
        let(:config) { default_config.merge(allowed_request_headers: ['foo_BAR']) }

        it 'returns attribute' do
          _(first_span.attributes['http.request.headers.foo_bar']).must_equal 'http foo bar value'
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
      it 'span.name is uri path' do
        _(first_span.name).must_equal '/really_long_url'
      end
    end

    describe 'with quantization' do
      let(:quantization_example) do
        # demonstrate simple shortening of URL:
        ->(url) { url.to_s[0..5] }
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
      _(first_span.status.canonical_code).must_equal OpenTelemetry::Trace::Status::UNKNOWN_ERROR
    end
  end
end
