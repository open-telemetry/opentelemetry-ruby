# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

require_relative '../../../lib/opentelemetry/adapters/sinatra'

describe OpenTelemetry::Adapters::Sinatra do
  include Rack::Test::Methods

  let(:adapter) { OpenTelemetry::Adapters::Sinatra }
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
    adapter.install
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

      _(exporter.finished_spans.first.attributes).must_equal ({
          "component" => "http",
          "http.method"=>"GET",
          "http.url"=>"/endpoint",
          "http.status_code"=>200,
          "http.status_text"=>"OK",
          "http.route"=>"/endpoint" })
    end

    it 'traces templates' do
      get '/one/with_template'

      _(exporter.finished_spans.size).must_equal 3
      _(exporter.finished_spans.map(&:name)).
        must_equal ['sinatra.render_template',
                    'sinatra.render_template',
                    '/with_template']
      _(exporter.finished_spans[0..1].map(&:attributes).
        map {|h| h['sinatra.template_name']}).
        must_equal ['layout', 'foo_template']
    end
  end
end
