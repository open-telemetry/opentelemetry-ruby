# frozen_string_literal: true

# Copyright 2020 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::Instrumentation::Rails::Middlewares::TracerMiddleware do
  include Rack::Test::Methods

  let(:instrumentation) { OpenTelemetry::Instrumentation::Rails::Instrumentation.instance }
  let(:exporter) { EXPORTER }
  let(:spans) { exporter.finished_spans }
  let(:span) { exporter.finished_spans.last }

  # Clear captured spans
  before { exporter.reset }

  it 'traces controller requests' do
    get '/ok'

    _(last_response.body).must_equal 'actually ok'
    _(last_response.ok?).must_equal true

    _(span.name).must_equal 'ExampleController.ok'
    _(span.kind).must_equal :server
    _(span.status.ok?).must_equal true

    _(span.instrumentation_library.name).must_equal 'OpenTelemetry::Instrumentation::Rails'
    _(span.instrumentation_library.version).must_equal OpenTelemetry::Instrumentation::Rails::VERSION

    _(span.attributes['http.method']).must_equal 'GET'
    _(span.attributes['http.host']).must_equal 'example.org'
    _(span.attributes['http.scheme']).must_equal 'http'
    _(span.attributes['http.target']).must_equal '/ok'
    _(span.attributes['http.status_code']).must_equal 200
    _(span.attributes['rails.controller']).must_equal 'ExampleController'
    _(span.attributes['rails.action']).must_equal 'ok'
  end

  it 'traces the request when it raises in middleware' do
    get '/exception'

    _(span.name).must_equal '/exception'
    _(span.kind).must_equal :server
    _(span.status.ok?).must_equal false

    _(span.attributes['http.method']).must_equal 'GET'
    _(span.attributes['http.host']).must_equal 'example.org'
    _(span.attributes['http.scheme']).must_equal 'http'
    _(span.attributes['http.target']).must_equal '/exception'
    _(span.attributes['http.status_code']).must_equal 500
  end

  it 'traces the request when it redirects in middleware' do
    get '/redirection'

    _(span.name).must_equal '/redirection'
    _(span.kind).must_equal :server
    _(span.status.ok?).must_equal true

    _(span.attributes['http.method']).must_equal 'GET'
    _(span.attributes['http.host']).must_equal 'example.org'
    _(span.attributes['http.scheme']).must_equal 'http'
    _(span.attributes['http.target']).must_equal '/redirection'
    _(span.attributes['http.status_code']).must_equal 307
  end

  def app
    ::Rails.application
  end
end
