# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

require_relative '../../../../../../lib/opentelemetry/instrumentation/action_pack'
require_relative '../../../../../../lib/opentelemetry/instrumentation/action_pack/patches/action_controller/metal'

describe OpenTelemetry::Instrumentation::ActionPack::Patches::ActionController::Metal do
  include Rack::Test::Methods

  let(:exporter) { EXPORTER }
  let(:spans) { exporter.finished_spans }
  let(:span) { exporter.finished_spans.last }
  let(:rails_app) { DEFAULT_RAILS_APP }

  # Clear captured spans
  before { exporter.reset }

  it 'sets the span name to ControllerName#action' do
    get '/ok'

    _(last_response.body).must_equal 'actually ok'
    _(last_response.ok?).must_equal true
    _(span.name).must_equal 'ExampleController#ok'
    _(span.kind).must_equal :server
    _(span.status.ok?).must_equal true

    _(span.instrumentation_library.name).must_equal 'OpenTelemetry::Instrumentation::Rack'
    _(span.instrumentation_library.version).must_equal OpenTelemetry::Instrumentation::Rack::VERSION

    _(span.attributes['http.method']).must_equal 'GET'
    _(span.attributes['http.host']).must_equal 'example.org'
    _(span.attributes['http.scheme']).must_equal 'http'
    _(span.attributes['http.target']).must_equal '/ok'
    _(span.attributes['http.status_code']).must_equal 200
    _(span.attributes['http.user_agent']).must_be_nil
    _(span.attributes['http.route']).must_be_nil
  end

  it 'sets the span name when the controller raises an exception' do
    get 'internal_server_error'

    _(span.name).must_equal 'ExampleController#internal_server_error'
  end

  it 'does not set the span name when an exception is raised in middleware' do
    get '/ok?raise_in_middleware'

    _(span.name).must_equal 'HTTP GET'
  end

  it 'does not set the span name when the request is redirected in middleware' do
    get '/ok?redirect_in_middleware'

    _(span.name).must_equal 'HTTP GET'
  end

  describe 'when the application has exceptions_app configured' do
    let(:rails_app) { AppConfig.initialize_app(use_exceptions_app: true) }

    it 'does not overwrite the span name from the controller that raised' do
      get 'internal_server_error'

      _(span.name).must_equal 'ExampleController#internal_server_error'
    end
  end

  describe 'when the application has enable_rails_route enabled' do
    before do
      OpenTelemetry::Instrumentation::ActionPack::Instrumentation.instance.config[:enable_recognize_route] = true
    end

    after do
      OpenTelemetry::Instrumentation::ActionPack::Instrumentation.instance.config[:enable_recognize_route] = false
    end

    it 'sets the span name to ControllerName#action' do
      get '/ok'
      _(last_response.body).must_equal 'actually ok'
      _(last_response.ok?).must_equal true
      _(span.name).must_equal 'ExampleController#ok'
      _(span.kind).must_equal :server
      _(span.status.ok?).must_equal true

      _(span.instrumentation_library.name).must_equal 'OpenTelemetry::Instrumentation::Rack'
      _(span.instrumentation_library.version).must_equal OpenTelemetry::Instrumentation::Rack::VERSION

      _(span.attributes['http.method']).must_equal 'GET'
      _(span.attributes['http.host']).must_equal 'example.org'
      _(span.attributes['http.scheme']).must_equal 'http'
      _(span.attributes['http.target']).must_equal '/ok'
      _(span.attributes['http.status_code']).must_equal 200
      _(span.attributes['http.user_agent']).must_be_nil
      _(span.attributes['http.route']).must_equal '/ok(.:format)'
    end
  end

  describe 'when the application does not have the tracing rack middleware' do
    let(:rails_app) { AppConfig.initialize_app(remove_rack_tracer_middleware: true) }

    it 'does something' do
      get '/ok'

      _(last_response.body).must_equal 'actually ok'
      _(last_response.ok?).must_equal true
      _(spans.size).must_equal(0)
    end
  end

  def app
    rails_app
  end
end
