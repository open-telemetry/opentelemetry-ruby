# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0
require 'test_helper'
require 'faux_writer_helper'

# Give access to otherwise private members
module OpenTelemetry
  module Exporters
    module Datadog
      class Exporter
        attr_accessor :agent_writer, :agent_url, :service, :env, :version, :tags
      end
    end
  end
end

describe OpenTelemetry::Exporters::Datadog::Exporter do
  SUCCESS = begin
              OpenTelemetry::SDK::Trace::Export::SUCCESS
            rescue NameError
              0
            end
  FAILURE = begin
              OpenTelemetry::SDK::Trace::Export::FAILURE
            rescue NameError
              1
            end
  AGENT_URL = 'http://localhost:8126'

  let(:service_name) { 'test' }
  let(:agent_url) { 'http://localhost:8126' }
  let(:tracing_env) { nil }
  let(:tracing_version) { nil }
  let(:tracing_tags) { nil }

  let(:faux_writer) do
    FauxWriter.new(
      transport: Datadog::Transport::HTTP.default do |t|
        t.adapter :test
      end
    )
  end

  let(:exporter) do
    OpenTelemetry::Exporters::Datadog::Exporter.new(service_name: service_name, agent_url: agent_url, env: tracing_env, version: tracing_version, tags: tracing_tags).tap do |exporter|
      exporter.agent_writer = faux_writer
    end
  end

  describe '#initialize' do
    let(:service_name) { nil }
    let(:agent_url) { nil }

    it 'initializes' do
      _(exporter).wont_be_nil
    end

    it 'initializes with defaults' do
      default_exporter = exporter
      _(default_exporter.agent_url).must_equal('http://localhost:8126')
      _(default_exporter.service).must_equal('my_service')
      assert_nil(default_exporter.tags)
      assert_nil(default_exporter.env)
      assert_nil(default_exporter.version)
    end

    it 'initializes with environment variables as defaults' do
      env_url = 'http://localhost:8127'
      env_service = 'env_service'
      env_tags = 'exampletagkey:exampletagvalue,anotherkey:anothervalue'
      env_env = 'prod'
      env_version = '1'

      ENV['DD_TRACE_AGENT_URL'] = env_url
      ENV['DD_SERVICE'] = env_service
      ENV['DD_TAGS'] = env_tags
      ENV['DD_ENV'] = env_env
      ENV['DD_VERSION'] = env_version

      begin
        default_exporter = exporter

        _(default_exporter.agent_url).must_equal(env_url)
        _(default_exporter.service).must_equal(env_service)
        _(default_exporter.tags).must_equal(env_tags)
        _(default_exporter.env).must_equal(env_env)
        _(default_exporter.version).must_equal(env_version)
      ensure
        ENV.delete('DD_TRACE_AGENT_URL')
        ENV.delete('DD_SERVICE')
        ENV.delete('DD_TAGS')
        ENV.delete('DD_ENV')
        ENV.delete('DD_VERSION')
      end
    end

    describe '#initialize precedence' do
      let(:service_name) { 'test' }
      let(:agent_url) { 'http://localhost:8128' }
      let(:tracing_env) { 'staging' }
      let(:tracing_version) { '2' }
      let(:tracing_tags) { 'altkey:altvalue' }

      it 'initializes with arguments taking precedence over environment variables' do
        env_url = 'http://localhost:8127'
        env_service = 'env_service'
        env_tags = 'exampletagkey:exampletagvalue,anotherkey:anothervalue'
        env_env = 'prod'
        env_version = '1'

        ENV['DD_TRACE_AGENT_URL'] = env_url
        ENV['DD_SERVICE'] = env_service
        ENV['DD_TAGS'] = env_tags
        ENV['DD_ENV'] = env_env
        ENV['DD_VERSION'] = env_version
        ENV['DD_TRACE_AGENT_URL'] = env_url

        begin
          default_exporter = exporter

          _(default_exporter.agent_url).must_equal(agent_url)
          _(default_exporter.service).must_equal(service_name)
          _(default_exporter.tags).must_equal(tracing_tags)
          _(default_exporter.env).must_equal(tracing_env)
          _(default_exporter.version).must_equal(tracing_version)
        ensure
          ENV.delete('DD_TRACE_AGENT_URL')
          ENV.delete('DD_SERVICE')
          ENV.delete('DD_TAGS')
          ENV.delete('DD_ENV')
          ENV.delete('DD_VERSION')
        end
      end
    end

    # describe '#initializes with uds writer' do
    # end
  end

  describe '#export' do
    before do
      OpenTelemetry.tracer_provider = OpenTelemetry::SDK::Trace::TracerProvider.new
    end

    it 'returns FAILURE when shutdown' do
      exporter.shutdown
      result = exporter.export(nil)
      _(result).must_equal(FAILURE)
    end

    it 'exports a span_data' do
      span_data = create_span_data
      result = exporter.export([span_data])
      packet = exporter.agent_writer.spans
      _(result).must_equal(SUCCESS)
      _(packet).wont_be_nil
    end

    it 'exports a span from a tracer' do
      span_name = 'foo'
      processor = OpenTelemetry::Exporters::Datadog::DatadogSpanProcessor.new(exporter: exporter)
      OpenTelemetry.tracer_provider.add_span_processor(processor)
      OpenTelemetry.tracer_provider.tracer.start_root_span(span_name).finish
      OpenTelemetry.tracer_provider.shutdown
      packet = exporter.agent_writer.spans
      _(packet).wont_be_nil
      _(packet[0].name).must_equal(span_name)
    end
  end

  def create_span_data(name: '', kind: nil, status: nil, parent_span_id: OpenTelemetry::Trace::INVALID_SPAN_ID, child_count: 0,
                       total_recorded_attributes: 0, total_recorded_events: 0, total_recorded_links: 0, start_timestamp: Time.now,
                       end_timestamp: Time.now, attributes: nil, links: nil, events: nil, library_resource: nil, instrumentation_library: nil,
                       span_id: OpenTelemetry::Trace.generate_span_id, trace_id: OpenTelemetry::Trace.generate_trace_id,
                       trace_flags: OpenTelemetry::Trace::TraceFlags::DEFAULT)
    OpenTelemetry::SDK::Trace::SpanData.new(name, kind, status, parent_span_id, child_count, total_recorded_attributes,
                                            total_recorded_events, total_recorded_links, start_timestamp, end_timestamp,
                                            attributes, links, events, library_resource, instrumentation_library, span_id, trace_id, trace_flags)
  end
end
