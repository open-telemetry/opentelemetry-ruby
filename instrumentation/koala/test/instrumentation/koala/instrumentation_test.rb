# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'
require 'pry'

require_relative '../../../lib/opentelemetry/instrumentation/koala'
require_relative '../../../../net_http/lib/opentelemetry/instrumentation/net/http'

describe OpenTelemetry::Instrumentation::Koala do # rubocop:disable Metrics/BlockLength
  let(:instrumentation) { OpenTelemetry::Instrumentation::Koala::Instrumentation.instance }
  let(:http_instrumentation) { OpenTelemetry::Instrumentation::Net::HTTP::Instrumentation.instance }
  let(:exporter) { EXPORTER }
  let(:span) { exporter.finished_spans.first }

  it 'has #name' do
    _(instrumentation.name).must_equal 'OpenTelemetry::Instrumentation::Koala'
  end

  it 'has #version' do
    _(instrumentation.version).wont_be_nil
    _(instrumentation.version).wont_be_empty
  end

  describe '#install' do
    it 'accepts argument' do
      instrumentation.install({})
    end
  end

  describe 'install' do
    before do
      exporter.reset
      http_instrumentation.install({})
      instrumentation.install({})
    end

    it 'when koala call made' do
      stub_request(:get, 'https://graph.facebook.com/me?access_token=fake_token')
        .to_return(status: 200, body: '{"id":"2531656920449469","name":"First Last"}', headers: {})

      @graph = Koala::Facebook::API.new('fake_token')
      @graph.get_object('me')
      _(exporter.finished_spans.size).must_equal 1
      span = exporter.finished_spans.first
      _(span.attributes['koala.verb']).must_equal 'get'
      _(span.attributes['koala.path']).must_equal 'me'
    end
  end
end
