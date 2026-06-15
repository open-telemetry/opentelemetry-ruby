# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::OtelConfig do
  # Temporarily replaces build_instrumentation_name_map with a stub that
  # returns +map+, then restores the original after the block.
  def with_name_map(map)
    original = OpenTelemetry::OtelConfig.method(:build_instrumentation_name_map)
    OpenTelemetry::OtelConfig.singleton_class.undef_method(:build_instrumentation_name_map)
    OpenTelemetry::OtelConfig.define_singleton_method(:build_instrumentation_name_map) { map }
    yield
  ensure
    OpenTelemetry::OtelConfig.singleton_class.undef_method(:build_instrumentation_name_map)
    OpenTelemetry::OtelConfig.define_singleton_method(:build_instrumentation_name_map, original)
  end

  # Temporarily replaces OpenTelemetry::Instrumentation.registry with a fake
  # registry containing +classes+, then restores the original method.
  def with_registry_classes(classes)
    fake_registry = Object.new
    fake_registry.instance_variable_set(:@instrumentation, classes)

    original = OpenTelemetry::Instrumentation.method(:registry)
    OpenTelemetry::Instrumentation.singleton_class.undef_method(:registry)
    OpenTelemetry::Instrumentation.define_singleton_method(:registry) { fake_registry }
    yield
  ensure
    OpenTelemetry::Instrumentation.singleton_class.undef_method(:registry)
    OpenTelemetry::Instrumentation.define_singleton_method(:registry, original)
  end

  # Builds a fake instrumentation class that responds to .instance and returns
  # an object exposing a #name string.
  def fake_instrumentation_class(full_name)
    instance = Struct.new(:name).new(full_name)
    Class.new.tap do |klass|
      klass.define_singleton_method(:instance) { instance }
    end
  end

  # Fake name map used throughout the stubbed unit tests.
  FAKE_NAME_MAP = {
    'net_http' => 'OpenTelemetry::Instrumentation::Net::HTTP',
    'rack' => 'OpenTelemetry::Instrumentation::Rack',
    'redis' => 'OpenTelemetry::Instrumentation::Redis',
    'sidekiq' => 'OpenTelemetry::Instrumentation::Sidekiq',
    'active_job' => 'OpenTelemetry::Instrumentation::ActiveJob',
    'faraday' => 'OpenTelemetry::Instrumentation::Faraday',
    'mysql2' => 'OpenTelemetry::Instrumentation::Mysql2',
    'pg' => 'OpenTelemetry::Instrumentation::PG',
    'grpc' => 'OpenTelemetry::Instrumentation::GRPC',
    'graphql' => 'OpenTelemetry::Instrumentation::GraphQL',
    'dalli' => 'OpenTelemetry::Instrumentation::Dalli',
    'action_pack' => 'OpenTelemetry::Instrumentation::ActionPack'
  }.freeze

  describe 'instrumentation' do
    describe 'build_instrumentation_name_map' do
      it 'returns a Hash for the current registry' do
        result = OpenTelemetry::OtelConfig.build_instrumentation_name_map

        _(result).must_be_kind_of Hash
      end

      it 'maps full instrumentation names to snake_case short names' do
        classes = [
          fake_instrumentation_class('OpenTelemetry::Instrumentation::Net::HTTP'),
          fake_instrumentation_class('OpenTelemetry::Instrumentation::ActionPack'),
          fake_instrumentation_class('OpenTelemetry::Instrumentation::Redis')
        ]

        with_registry_classes(classes) do
          result = OpenTelemetry::OtelConfig.build_instrumentation_name_map

          _(result).must_equal(
            'net_http' => 'OpenTelemetry::Instrumentation::Net::HTTP',
            'action_pack' => 'OpenTelemetry::Instrumentation::ActionPack',
            'redis' => 'OpenTelemetry::Instrumentation::Redis'
          )
        end
      end

      it 'joins nested module segments with underscores' do
        classes = [
          fake_instrumentation_class('OpenTelemetry::Instrumentation::Foo::Bar::HTTP')
        ]

        with_registry_classes(classes) do
          result = OpenTelemetry::OtelConfig.build_instrumentation_name_map

          _(result['foo_bar_http']).must_equal 'OpenTelemetry::Instrumentation::Foo::Bar::HTTP'
        end
      end

      it 'returns {} when registry instrumentation data is invalid' do
        with_registry_classes(nil) do
          result = OpenTelemetry::OtelConfig.build_instrumentation_name_map

          _(result).must_equal({})
        end
      end
    end

    describe 'configure_from_file with instrumentation section' do
      it 'does not raise when the instrumentation section is absent' do
        with_config(<<~YAML) do |path|
          file_format: "1.0"
          #{TRACER_PROVIDER_YAML}
        YAML
          sdk = OpenTelemetry::OtelConfig.configure_from_file(path)
          OpenTelemetry.tracer_provider = sdk.tracer_provider

          _(OpenTelemetry.tracer_provider).must_be_instance_of OpenTelemetry::SDK::Trace::TracerProvider
        end
      end

      it 'does not raise when instrumentation gems are not installed' do
        with_config(<<~YAML) do |path|
          file_format: "1.0"
          #{TRACER_PROVIDER_YAML}
          instrumentation:
            ruby:
              net_http:
                untraced_hosts:
                  - example.com
              rack:
                record_frontend_span: false
        YAML
          sdk = OpenTelemetry::OtelConfig.configure_from_file(path)
          OpenTelemetry.tracer_provider = sdk.tracer_provider

          _(OpenTelemetry.tracer_provider).must_be_instance_of OpenTelemetry::SDK::Trace::TracerProvider
        end
      end

      it 'does not raise for multiple instrumentations with mixed option types' do
        with_config(<<~YAML) do |path|
          file_format: "1.0"
          #{TRACER_PROVIDER_YAML}
          instrumentation:
            ruby:
              redis:
                peer_service: "cache-cluster"
                trace_root_spans: true
                db_statement: obfuscate
              sidekiq:
                span_naming: queue
                propagation_style: link
                trace_launcher_heartbeat: false
              active_job:
                propagation_style: child
                force_flush: true
                span_naming: job_class
        YAML
          sdk = OpenTelemetry::OtelConfig.configure_from_file(path)
          OpenTelemetry.tracer_provider = sdk.tracer_provider

          _(OpenTelemetry.tracer_provider).must_be_instance_of OpenTelemetry::SDK::Trace::TracerProvider
        end
      end
    end

    # build_instrumentation_config_map — nil / invalid inputs
    describe 'build_instrumentation_config_map with invalid inputs' do
      it 'returns {} when config is nil' do
        _(OpenTelemetry::OtelConfig.build_instrumentation_config_map(nil)).must_equal({})
      end

      it 'returns {} when config is not a Hash' do
        _(OpenTelemetry::OtelConfig.build_instrumentation_config_map('string')).must_equal({})
        _(OpenTelemetry::OtelConfig.build_instrumentation_config_map(42)).must_equal({})
      end

      it 'returns {} when the ruby key is absent' do
        _(OpenTelemetry::OtelConfig.build_instrumentation_config_map({ 'other' => {} })).must_equal({})
      end

      it 'returns {} when ruby is not a Hash' do
        _(OpenTelemetry::OtelConfig.build_instrumentation_config_map({ 'ruby' => 'flat' })).must_equal({})
        _(OpenTelemetry::OtelConfig.build_instrumentation_config_map({ 'ruby' => [] })).must_equal({})
      end

      it 'returns {} when ruby is an empty Hash' do
        _(OpenTelemetry::OtelConfig.build_instrumentation_config_map({ 'ruby' => {} })).must_equal({})
      end
    end

    # build_instrumentation_config_map — transformation logic (stubbed name map)
    describe 'build_instrumentation_config_map with stubbed name map' do
      describe 'core transformation behaviour' do
        it 'maps the short name to the full class name' do
          with_name_map(FAKE_NAME_MAP) do
            cfg = { 'ruby' => { 'net_http' => {} } }
            result = OpenTelemetry::OtelConfig.build_instrumentation_config_map(cfg)
            _(result.keys).must_include 'OpenTelemetry::Instrumentation::Net::HTTP'
          end
        end

        it 'symbolizes option keys' do
          with_name_map(FAKE_NAME_MAP) do
            cfg = { 'ruby' => { 'net_http' => { 'untraced_hosts' => ['localhost'] } } }
            result = OpenTelemetry::OtelConfig.build_instrumentation_config_map(cfg)
            opts = result['OpenTelemetry::Instrumentation::Net::HTTP']
            _(opts.keys).must_include :untraced_hosts
            _(opts.keys).wont_include 'untraced_hosts'
          end
        end

        it 'treats nil options as an empty Hash' do
          with_name_map(FAKE_NAME_MAP) do
            cfg = { 'ruby' => { 'net_http' => nil } }
            result = OpenTelemetry::OtelConfig.build_instrumentation_config_map(cfg)
            _(result['OpenTelemetry::Instrumentation::Net::HTTP']).must_equal({})
          end
        end

        it 'treats non-Hash options as an empty Hash' do
          with_name_map(FAKE_NAME_MAP) do
            cfg = { 'ruby' => { 'net_http' => 'enabled' } }
            result = OpenTelemetry::OtelConfig.build_instrumentation_config_map(cfg)
            _(result['OpenTelemetry::Instrumentation::Net::HTTP']).must_equal({})
          end
        end

        it 'skips and does not include unknown short names' do
          with_name_map(FAKE_NAME_MAP) do
            cfg = { 'ruby' => { 'totally_unknown_lib' => { 'opt' => 1 } } }
            result = OpenTelemetry::OtelConfig.build_instrumentation_config_map(cfg)
            _(result).must_equal({})
          end
        end

        it 'maps multiple instrumentations in one call' do
          with_name_map(FAKE_NAME_MAP) do
            cfg = {
              'ruby' => {
                'net_http' => { 'untraced_hosts' => ['internal.example.com'] },
                'redis' => { 'peer_service' => 'cache', 'trace_root_spans' => true }
              }
            }
            result = OpenTelemetry::OtelConfig.build_instrumentation_config_map(cfg)
            _(result.size).must_equal 2
            _(result['OpenTelemetry::Instrumentation::Net::HTTP']).must_equal(untraced_hosts: ['internal.example.com'])
            _(result['OpenTelemetry::Instrumentation::Redis']).must_equal(peer_service: 'cache', trace_root_spans: true)
          end
        end
      end

      # Representative option shapes from each instrumentation
      describe 'net_http options' do
        it 'maps untraced_hosts array' do
          with_name_map(FAKE_NAME_MAP) do
            cfg = { 'ruby' => { 'net_http' => { 'untraced_hosts' => ['metrics.example.com', 'localhost'] } } }
            result = OpenTelemetry::OtelConfig.build_instrumentation_config_map(cfg)
            _(result['OpenTelemetry::Instrumentation::Net::HTTP']).must_equal(
              untraced_hosts: ['metrics.example.com', 'localhost']
            )
          end
        end
      end

      describe 'rack options' do
        it 'maps all rack options correctly' do
          with_name_map(FAKE_NAME_MAP) do
            cfg = {
              'ruby' => {
                'rack' => {
                  'allowed_request_headers' => %w[X-Request-ID X-Forwarded-For],
                  'allowed_response_headers' => ['X-Response-Time'],
                  'untraced_endpoints' => ['/healthz', '/metrics'],
                  'record_frontend_span' => true,
                  'use_rack_events' => false
                }
              }
            }
            result = OpenTelemetry::OtelConfig.build_instrumentation_config_map(cfg)
            opts = result['OpenTelemetry::Instrumentation::Rack']
            _(opts[:allowed_request_headers]).must_equal %w[X-Request-ID X-Forwarded-For]
            _(opts[:allowed_response_headers]).must_equal ['X-Response-Time']
            _(opts[:untraced_endpoints]).must_equal ['/healthz', '/metrics']
            _(opts[:record_frontend_span]).must_equal true
            _(opts[:use_rack_events]).must_equal false
          end
        end
      end

      describe 'redis options' do
        it 'maps peer_service, trace_root_spans, and db_statement' do
          with_name_map(FAKE_NAME_MAP) do
            cfg = {
              'ruby' => {
                'redis' => {
                  'peer_service' => 'redis-primary',
                  'trace_root_spans' => false,
                  'db_statement' => 'obfuscate'
                }
              }
            }
            result = OpenTelemetry::OtelConfig.build_instrumentation_config_map(cfg)
            opts = result['OpenTelemetry::Instrumentation::Redis']
            _(opts[:peer_service]).must_equal 'redis-primary'
            _(opts[:trace_root_spans]).must_equal false
            _(opts[:db_statement]).must_equal 'obfuscate'
          end
        end
      end

      describe 'sidekiq options' do
        it 'maps span_naming, propagation_style, and boolean trace flags' do
          with_name_map(FAKE_NAME_MAP) do
            cfg = {
              'ruby' => {
                'sidekiq' => {
                  'span_naming' => 'job_class',
                  'propagation_style' => 'child',
                  'trace_launcher_heartbeat' => true,
                  'trace_poller_enqueue' => false,
                  'trace_poller_wait' => false,
                  'trace_processor_process_one' => true,
                  'peer_service' => 'sidekiq-workers'
                }
              }
            }
            result = OpenTelemetry::OtelConfig.build_instrumentation_config_map(cfg)
            opts = result['OpenTelemetry::Instrumentation::Sidekiq']
            _(opts[:span_naming]).must_equal 'job_class'
            _(opts[:propagation_style]).must_equal 'child'
            _(opts[:trace_launcher_heartbeat]).must_equal true
            _(opts[:trace_poller_enqueue]).must_equal false
            _(opts[:trace_processor_process_one]).must_equal true
            _(opts[:peer_service]).must_equal 'sidekiq-workers'
          end
        end
      end

      describe 'active_job options' do
        it 'maps propagation_style, force_flush, and span_naming' do
          with_name_map(FAKE_NAME_MAP) do
            cfg = {
              'ruby' => {
                'active_job' => {
                  'propagation_style' => 'none',
                  'force_flush' => true,
                  'span_naming' => 'job_class'
                }
              }
            }
            result = OpenTelemetry::OtelConfig.build_instrumentation_config_map(cfg)
            opts = result['OpenTelemetry::Instrumentation::ActiveJob']
            _(opts[:propagation_style]).must_equal 'none'
            _(opts[:force_flush]).must_equal true
            _(opts[:span_naming]).must_equal 'job_class'
          end
        end
      end

      describe 'faraday options' do
        it 'maps span_kind, peer_service, and enable_internal_instrumentation' do
          with_name_map(FAKE_NAME_MAP) do
            cfg = {
              'ruby' => {
                'faraday' => {
                  'span_kind' => 'internal',
                  'peer_service' => 'downstream-api',
                  'enable_internal_instrumentation' => true
                }
              }
            }
            result = OpenTelemetry::OtelConfig.build_instrumentation_config_map(cfg)
            opts = result['OpenTelemetry::Instrumentation::Faraday']
            _(opts[:span_kind]).must_equal 'internal'
            _(opts[:peer_service]).must_equal 'downstream-api'
            _(opts[:enable_internal_instrumentation]).must_equal true
          end
        end
      end

      describe 'mysql2 options' do
        it 'maps db_statement, obfuscation_limit, span_name, and peer_service' do
          with_name_map(FAKE_NAME_MAP) do
            cfg = {
              'ruby' => {
                'mysql2' => {
                  'peer_service' => 'mysql-primary',
                  'db_statement' => 'omit',
                  'span_name' => 'db_name',
                  'obfuscation_limit' => 500
                }
              }
            }
            result = OpenTelemetry::OtelConfig.build_instrumentation_config_map(cfg)
            opts = result['OpenTelemetry::Instrumentation::Mysql2']
            _(opts[:peer_service]).must_equal 'mysql-primary'
            _(opts[:db_statement]).must_equal 'omit'
            _(opts[:span_name]).must_equal 'db_name'
            _(opts[:obfuscation_limit]).must_equal 500
          end
        end
      end

      describe 'pg options' do
        it 'maps db_statement, obfuscation_limit, and peer_service' do
          with_name_map(FAKE_NAME_MAP) do
            cfg = {
              'ruby' => {
                'pg' => {
                  'peer_service' => 'postgres-replica',
                  'db_statement' => 'include',
                  'obfuscation_limit' => 1000
                }
              }
            }
            result = OpenTelemetry::OtelConfig.build_instrumentation_config_map(cfg)
            opts = result['OpenTelemetry::Instrumentation::PG']
            _(opts[:peer_service]).must_equal 'postgres-replica'
            _(opts[:db_statement]).must_equal 'include'
            _(opts[:obfuscation_limit]).must_equal 1000
          end
        end
      end

      describe 'grpc options' do
        it 'maps allowed_metadata_headers and peer_service' do
          with_name_map(FAKE_NAME_MAP) do
            cfg = {
              'ruby' => {
                'grpc' => {
                  'allowed_metadata_headers' => %w[x-correlation-id x-tenant-id],
                  'peer_service' => 'grpc-backend'
                }
              }
            }
            result = OpenTelemetry::OtelConfig.build_instrumentation_config_map(cfg)
            opts = result['OpenTelemetry::Instrumentation::GRPC']
            _(opts[:allowed_metadata_headers]).must_equal %w[x-correlation-id x-tenant-id]
            _(opts[:peer_service]).must_equal 'grpc-backend'
          end
        end
      end

      describe 'graphql options' do
        it 'maps schemas array and all boolean platform flags' do
          with_name_map(FAKE_NAME_MAP) do
            cfg = {
              'ruby' => {
                'graphql' => {
                  'schemas' => [],
                  'enable_platform_field' => true,
                  'enable_platform_authorized' => false,
                  'enable_platform_resolve_type' => true,
                  'legacy_platform_span_names' => false,
                  'legacy_tracing' => false
                }
              }
            }
            result = OpenTelemetry::OtelConfig.build_instrumentation_config_map(cfg)
            opts = result['OpenTelemetry::Instrumentation::GraphQL']
            _(opts[:schemas]).must_equal []
            _(opts[:enable_platform_field]).must_equal true
            _(opts[:enable_platform_authorized]).must_equal false
            _(opts[:enable_platform_resolve_type]).must_equal true
          end
        end
      end

      describe 'dalli options' do
        it 'maps peer_service and db_statement' do
          with_name_map(FAKE_NAME_MAP) do
            cfg = {
              'ruby' => {
                'dalli' => {
                  'peer_service' => 'memcached',
                  'db_statement' => 'omit'
                }
              }
            }
            result = OpenTelemetry::OtelConfig.build_instrumentation_config_map(cfg)
            opts = result['OpenTelemetry::Instrumentation::Dalli']
            _(opts[:peer_service]).must_equal 'memcached'
            _(opts[:db_statement]).must_equal 'omit'
          end
        end
      end

      describe 'action_pack options' do
        it 'maps span_naming' do
          with_name_map(FAKE_NAME_MAP) do
            cfg = { 'ruby' => { 'action_pack' => { 'span_naming' => 'class' } } }
            result = OpenTelemetry::OtelConfig.build_instrumentation_config_map(cfg)
            _(result['OpenTelemetry::Instrumentation::ActionPack']).must_equal(span_naming: 'class')
          end
        end
      end
    end
  end
end
