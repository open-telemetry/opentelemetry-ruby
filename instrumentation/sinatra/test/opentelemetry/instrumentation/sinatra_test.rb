# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

require_relative '../../../lib/opentelemetry/instrumentation/sinatra/instrumentation'

describe OpenTelemetry::Instrumentation::Sinatra do
  include Rack::Test::Methods

  let(:instrumentation) { OpenTelemetry::Instrumentation::Sinatra::Instrumentation.instance }
  let(:exporter) { EXPORTER }

  let(:app_one) do
    Class.new(Sinatra::Application) do
      get '/endpoint' do
        '1'
      end

      template :foo_template do
        'Foo Template'
      end

      get '/with_template' do
        erb :foo_template
      end

      get '/api/v1/foo/:myname/?' do
        'Some name'
      end
    end
  end

  let(:app_two) do
    Class.new(Sinatra::Application) do
      get '/endpoint' do
        '2'
      end
    end
  end

  let(:apps) do
    {
      '/one' => app_one,
      '/two' => app_two
    }
  end

  let(:app) do
    apps_to_build = apps

    Rack::Builder.new do
      apps_to_build.each do |root, app|
        map root do
          run app
        end
      end
    end.to_app
  end

  before do
    instrumentation.install
    exporter.reset
  end

  describe 'tracing' do
    it 'before request' do
      _(exporter.finished_spans.size).must_equal 0
    end

    it 'after request' do
      get '/one/endpoint'

      _(exporter.finished_spans.size).must_equal 1
    end

    it 'traces all apps' do
      get '/two/endpoint'

      _(exporter.finished_spans.size).must_equal 1
    end

    it 'records attributes' do
      get '/one/endpoint'

      _(exporter.finished_spans.first.attributes).must_equal(
        'http.method' => 'GET',
        'http.url' => '/endpoint',
        'http.status_code' => 200,
        'http.route' => '/endpoint'
      )
    end

    it 'traces templates' do
      get '/one/with_template'

      _(exporter.finished_spans.size).must_equal 3
      _(exporter.finished_spans.map(&:name))
        .must_equal [
          'sinatra.render_template',
          'sinatra.render_template',
          'GET /with_template'
        ]
      _(exporter.finished_spans[0..1].map(&:attributes)
        .map { |h| h['sinatra.template_name'] })
        .must_equal %w[layout foo_template]
    end

    it 'correctly name spans' do
      get '/one//api/v1/foo/janedoe/'

      _(exporter.finished_spans.size).must_equal 1
      _(exporter.finished_spans.first.attributes).must_equal(
        'http.method' => 'GET',
        'http.url' => '/api/v1/foo/janedoe/',
        'http.status_code' => 200,
        'http.route' => '/api/v1/foo/:myname/?'
      )
      _(exporter.finished_spans.map(&:name))
        .must_equal [
          'GET /api/v1/foo/:myname/?'
        ]
    end

    it 'does not create unhandled exceptions for missing routes' do
      get '/one/missing_example/not_present'

      _(exporter.finished_spans.first.status.code).must_equal OpenTelemetry::Trace::Status::UNSET
      _(exporter.finished_spans.first.attributes).must_equal(
        'http.method' => 'GET',
        'http.url' => '/missing_example/not_present',
        'http.status_code' => 404
      )
    end
  end
end
