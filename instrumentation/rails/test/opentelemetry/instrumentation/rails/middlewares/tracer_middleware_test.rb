# frozen_string_literal: true

# Copyright 2020 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'
require 'test_helpers/controllers'
require 'test_helpers/middlewares'

require_relative '../../../../../lib/opentelemetry/instrumentation/rails'
require_relative '../../../../../lib/opentelemetry/instrumentation/rails/instrumentation'
require_relative '../../../../../lib/opentelemetry/instrumentation/rails/middlewares/tracer_middleware'

describe OpenTelemetry::Instrumentation::Rails::Middlewares::TracerMiddleware do
  include Rack::Test::Methods

  let(:instrumentation) { OpenTelemetry::Instrumentation::Rails::Instrumentation.instance }
  let(:exporter) { EXPORTER }
  let(:spans) { exporter.finished_spans }
  let(:span) { exporter.finished_spans.last }
  let(:config) { {} }

  before do
    # Simulate a fresh install
    instrumentation.instance_variable_set('@installed', false)
    instrumentation.install(config)

    # Clear captured spans
    exporter.reset
  end

  it 'traces controller requests' do
    initialize_rails_app_and_set_routes

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

  describe 'when a middleware raises before the request reaches the controller' do
    before do
      app.middleware.insert_after(ActionDispatch::DebugExceptions, ExceptionRaisingMiddleware)
    end

    it 'traces controller requests' do
      initialize_rails_app_and_set_routes

      get '/ok'

      _(span.name).must_equal '/ok'
      _(span.kind).must_equal :server
      _(span.status.ok?).must_equal false

      _(span.attributes['http.method']).must_equal 'GET'
      _(span.attributes['http.host']).must_equal 'example.org'
      _(span.attributes['http.scheme']).must_equal 'http'
      _(span.attributes['http.target']).must_equal '/ok'
      _(span.attributes['http.status_code']).must_equal 500
    end
  end

  describe 'when a middleware redirects before the request reaches the controller' do
    before do
      app.middleware.insert_after(ActionDispatch::DebugExceptions, RedirectMiddleware)
    end

    it 'traces controller requests' do
      initialize_rails_app_and_set_routes

      get '/ok'

      _(span.name).must_equal '/ok'
      _(span.kind).must_equal :server
      _(span.status.ok?).must_equal true

      _(span.attributes['http.method']).must_equal 'GET'
      _(span.attributes['http.host']).must_equal 'example.org'
      _(span.attributes['http.scheme']).must_equal 'http'
      _(span.attributes['http.target']).must_equal '/ok'
      _(span.attributes['http.status_code']).must_equal 307
    end
  end

  private

  def initialize_rails_app_and_set_routes
    app.initialize!
    app.routes.draw { get '/ok', to: 'example#ok' }
  end

  def app
    @app ||= Class.new(::Rails::Application) do
      config.eager_load = false # Ensure we don't see this Rails warning when testing
      config.logger = Logger.new('/dev/null') # Prevent tests from creating log/*.log
      config.secret_key_base = ('a' * 30)
    end
  end
end
