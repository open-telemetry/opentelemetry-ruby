# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0


require 'test_helper'
require_relative '../../../../local_server'
require_relative '../../../../../lib/opentelemetry/instrumentation/manticore/util/wrapped_request'

describe 'OpenTelemetry::Instrumentation::Manticore::Util::WrappedRequest' do
  describe '#.new is invoked and nil is passed' do
    it 'raises ArgumentError' do
      assert_raises ArgumentError do
        OpenTelemetry::Instrumentation::Manticore::Util::WrappedRequest.new(nil)
      end
    end
  end

  describe '#.new is invoked and Manticore::Client::Request is passed' do
    let(:uri) {'http://localhost:31000' }
    let(:wrapped_request) do
      LocalServer.start_server
      client = Manticore::Client.new
      request = client.get(uri)
      wr = OpenTelemetry::Instrumentation::Manticore::Util::WrappedRequest.new(request.request)
      wr
    end

    describe '#.set' do
      it 'sets specified header' do
        wrapped_request.set('FakeHeader', 'specs')
        _(wrapped_request.headers['FakeHeader']).must_equal('specs')
      end
    end

    describe '#.[]=' do
      it 'sets specified header' do
        wrapped_request['FakeHeader2'] = 'specs2'
        _(wrapped_request.headers['FakeHeader2']).must_equal('specs2')
      end
    end

    describe '#.headers' do
      it 'returns expected headers' do
        wrapped_request['FakeHeader3'] = 'specs3'
        _(wrapped_request.headers['FakeHeader3']).must_equal('specs3')
      end
    end

    describe '#.uri' do
      it 'returns correct uri provided in the request' do
        _(wrapped_request.uri).must_equal(uri)
      end
    end

    describe '#.method' do
      it 'returns the correct VERB of the request' do
        _(wrapped_request.method).must_equal('GET')
      end
    end

  end
end