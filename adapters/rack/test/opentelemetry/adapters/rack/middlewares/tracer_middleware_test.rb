# frozen_string_literal: true

# Copyright 2020 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

 #require Adapter so .install method is found:
require_relative '../../../../../lib/opentelemetry/adapters/rack'
require_relative '../../../../../lib/opentelemetry/adapters/rack/adapter'
require_relative '../../../../../lib/opentelemetry/adapters/rack/middlewares/tracer_middleware'

describe OpenTelemetry::Adapters::Rack::Middlewares::TracerMiddleware do
  let(:adapter_module) { OpenTelemetry::Adapters::Rack }
  let(:adapter) { adapter_module::Adapter }
  let(:app) { lambda { |env| [200, {'Content-Type' => 'text/plain'}, ['OK']] } }
  let(:described_class) { OpenTelemetry::Adapters::Rack::Middlewares::TracerMiddleware }
  let(:exporter) { EXPORTER }

  let(:rack_builder) { Rack::Builder.new }

  let(:middleware) { described_class.new(app) }
  let(:first_span) { exporter.finished_spans.first }

  let(:default_config) { Hash.new }
  let(:config) { default_config }
  let(:env) { Hash.new }

  before do
    adapter_module.install(config)
    exporter.reset

    rack_builder.run app
    rack_builder.use described_class
  end

  after do
    # installation is 'global', so it should be reset:
    adapter.instance_variable_set('@installed', false)
    adapter.install(default_config)
    adapter.instance_variable_set('@installed', false)
  end

  describe '#call' do
    before do
      Rack::MockRequest.new(rack_builder).get('/', env)
    end

    it 'records attributes' do
      _(first_span.attributes['component']).must_equal 'http'
      _(first_span.attributes['http.method']).must_equal 'GET'
      _(first_span.attributes['http.status_code']).must_equal 200
      _(first_span.attributes['http.status_text']).must_equal 'OK'
      _(first_span.status.canonical_code).must_equal OpenTelemetry::Trace::Status::OK
      _(first_span.attributes['http.url']).must_equal 'http://example.org/'
      _(first_span.name).must_equal '/'
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
        lambda { |env| [200, {'Foo-Bar' => 'foo bar response header'}, ['OK']] }
      end

      it 'defaults to nil' do
        _(first_span.attributes['http.response.headers.foo_bar']).must_be_nil
      end

      describe 'when configured' do
        let(:config) { default_config.merge(allowed_response_headers: ['Foo-Bar']) }

        it 'returns attribute' do
          _(first_span.attributes['http.response.headers.foo_bar']).must_equal 'foo bar response header'
        end

        describe "case-sensitively" do
          let(:config) { default_config.merge(allowed_response_headers: ['fOO-bAR']) }

          it 'returns attribute' do
            _(first_span.attributes['http.response.headers.foo_bar']).must_equal 'foo bar response header'
          end
        end
      end
    end

    describe 'config[:extract_parent_context]' do
      describe 'default' do
        it 'starts a trace without parent context' do
          _(first_span.parent_span_id).must_equal '0000000000000000'
        end
      end

      describe 'when true' do
        let(:config) { default_config.merge(extract_parent_context: true) }

        it 'extracts parent context' do
          _(first_span.parent_span_id).wont_equal '0000000000000000'
        end
      end
    end

    describe 'config[:record_frontend_span]' do
      describe 'default' do
        it 'does not record span' do
          _(exporter.finished_spans.size).must_equal 1
        end
      end

      describe 'when recordable' do
        let(:config) { default_config.merge(record_frontend_span: true)}
        let(:env) { Hash('HTTP_X_REQUEST_START' => Time.now.to_i) }

        it 'records span' do
          _(exporter.finished_spans.size).must_equal 2
          _(exporter.finished_spans.last.name).must_equal 'http_server.queue'
        end
      end
    end
  end
end
