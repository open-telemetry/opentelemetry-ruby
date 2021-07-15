# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::Instrumentation::Rails do
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

  def app
    rails_app
  end
end
