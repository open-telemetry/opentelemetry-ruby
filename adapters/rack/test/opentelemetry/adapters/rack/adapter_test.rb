# frozen_string_literal: true

# Copyright 2020 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

require_relative '../../../../lib/opentelemetry/adapters/rack/adapter'

describe OpenTelemetry::Adapters::Rack::Adapter do
  let(:adapter) { OpenTelemetry::Adapters::Rack::Adapter }

  after do
    # installation is 'global', so reset as much as possible:
    adapter.instance_variable_set('@installed', false)
    adapter.install({})
    adapter.instance_variable_set('@installed', false)
  end

  describe 'installation' do
    it 'gets installed' do
      _(adapter.install).must_equal true
    end

    it 'only installs once' do
      adapter.install

      _(adapter.install).must_equal :already_installed
    end
  end

  describe 'defaults' do
    before do
      adapter.install
    end

    it 'has propagator' do
      _(adapter.propagator).wont_be_nil
    end

    it 'has tracer' do
      _(adapter.tracer).wont_be_nil
    end
  end

  describe 'config[:retain_middleware_names]' do
    let(:config) { Hash(retain_middleware_names: true) }

    describe 'without config[:application]' do
      it 'raises error' do
        assert_raises adapter::MissingApplicationError do
          adapter.install(config)
        end
      end
    end

    describe 'default' do
      class MyAppClass
        attr_reader :env

        def call(env)
          @env = env
          [200, {'Content-Type' => 'text/plain'}, ['OK']]
        end
      end

      let(:app) { MyAppClass.new }

      describe 'without config' do
        it 'does not set RESPONSE_MIDDLEWARE' do
          app.call({})

          _(app.env['RESPONSE_MIDDLEWARE']).must_be_nil
        end
      end

      describe 'with config[:application]' do
        let(:config) do
          { retain_middleware_names: true,
            application: app }
        end

        it 'retains RESPONSE_MIDDLEWARE after .call' do
          adapter.install(config)
          app.call({})

          _(app.env['RESPONSE_MIDDLEWARE']).must_equal 'MyAppClass'
        end
      end
    end
  end
end
