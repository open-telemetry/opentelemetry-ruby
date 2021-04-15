# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'
require 'pry'

require_relative '../../../lib/opentelemetry/instrumentation/koala'

describe OpenTelemetry::Instrumentation::Koala do
  let(:instrumentation) { OpenTelemetry::Instrumentation::Koala::Instrumentation.instance }
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

  describe 'present' do
    it 'when koala gem installed' do
      _(instrumentation.present?).must_equal true
    end

    it 'when koala gem not installed' do
      hide_const('Koala')
      _(instrumentation.present?).must_equal false
    end
  end

  describe 'install' do
    before do
      exporter.reset
      instrumentation.install({})
    end

    it 'when koala call made' do
      stub_request(:get, 'https://graph.facebook.com/me?access_token=fake_token').with(
        headers: {
          'Accept' => '*/*',
          'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
          'User-Agent' => 'Faraday v1.3.0'
        }
      ).to_return(status: 200, body: '{"id":"2531656920449469","name":"Timur  Borkhodoev"}', headers: {})

      @graph = Koala::Facebook::API.new('fake_token')
      @graph.get_object('me')
      _(exporter.finished_spans.size).must_equal 1
    end
  end
end
