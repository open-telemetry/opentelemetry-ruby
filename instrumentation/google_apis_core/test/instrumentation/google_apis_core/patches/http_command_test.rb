# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

require_relative '../../../../lib/opentelemetry/instrumentation/google_apis_core'
require_relative '../../../../lib/opentelemetry/instrumentation/google_apis_core/patches/http_command'

describe OpenTelemetry::Instrumentation::GoogleApisCore::Patches::HttpCommand do
  let(:instrumentation) { OpenTelemetry::Instrumentation::GoogleApisCore::Instrumentation.instance }
  let(:exporter) { EXPORTER }
  let(:spans) { exporter.finished_spans }
  let(:client) { Google::Apis::Core::BaseService.new('', '').client }

  before do
    exporter.reset
    instrumentation.install({})
  end

  # Force re-install of instrumentation
  after { instrumentation.instance_variable_set(:@installed, false) }

  it 'it does not trace when not sampled' do
    stub_request(:get, 'https://www.googleapis.com/zoo/animals').to_return(status: [200, ''], body: "Hello world")
    command = Google::Apis::Core::HttpCommand.new(:get, 'https://www.googleapis.com/zoo/animals')
    command.execute(client)

    _(spans.size).must_equal(0)
  end

  it 'traces when in the context of a sampled trace' do
    stub_request(:get, 'https://www.googleapis.com/zoo/animals').to_return(status: [200, ''], body: "Hello world")
    command = Google::Apis::Core::HttpCommand.new(:get, 'https://www.googleapis.com/zoo/animals')
    instrumentation.tracer.in_span('test') { command.execute(client) }

    span = spans.find { |s| s.name == 'www.googleapis.com' }
    _(span.attributes['http.host']).must_equal('www.googleapis.com')
    _(span.attributes['http.method']).must_equal('get')
    _(span.attributes['http.target']).must_equal('/zoo/animals')
    _(span.attributes['http.status_code']).must_equal(200)
    _(span.status.ok?).must_equal(true)
  end

  it 'traces when there is an error' do
    stub_request(:get, 'https://www.googleapis.com/zoo/animals').to_return(status: [500, ''], body: "Hello world")
    command = Google::Apis::Core::HttpCommand.new(:get, 'https://www.googleapis.com/zoo/animals')

    _(-> { instrumentation.tracer.in_span('test') { command.execute(client) } }).must_raise(Google::Apis::ServerError)

    span = spans.find { |s| s.name == 'www.googleapis.com' }
    _(span.attributes['http.host']).must_equal('www.googleapis.com')
    _(span.attributes['http.method']).must_equal('get')
    _(span.attributes['http.target']).must_equal('/zoo/animals')
    _(span.attributes['http.status_code']).must_equal(500)
    _(span.status.ok?).must_equal(false)
  end
end
