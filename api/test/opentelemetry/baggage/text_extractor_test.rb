# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::Baggage::Propagation::TextMapExtractor do
  class MockBaggage
    def builder
      @builder ||= MiniTest::Mock.new
    end

    def build(context: _)
      yield builder
      OpenTelemetry::Context.empty
    end

    def expect(*args, &blk)
      builder.expect(*args, &blk)
    end

    def verify
      builder.verify
    end
  end

  let(:extractor) do
    OpenTelemetry::Baggage::Propagation::TextMapExtractor.new
  end
  let(:header_key) { 'baggage' }
  let(:mock_baggage) { MockBaggage.new }

  before do
    @original_baggage_mgr = OpenTelemetry.baggage
    OpenTelemetry.baggage = mock_baggage
  end

  after do
    OpenTelemetry.baggage = @original_baggage_mgr
  end

  describe '#extract' do
    describe 'valid headers' do
      it 'extracts key-value pairs' do
        mock_baggage.expect(:set_value, OpenTelemetry::Context.empty, %w[key1 val1])
        mock_baggage.expect(:set_value, OpenTelemetry::Context.empty, %w[key2 val2])
        carrier = { header_key => 'key1=val1,key2=val2' }
        extractor.extract(carrier, Context.empty)
        mock_baggage.verify
      end

      it 'extracts entries with spaces' do
        mock_baggage.expect(:set_value, OpenTelemetry::Context.empty, %w[key1 val1])
        mock_baggage.expect(:set_value, OpenTelemetry::Context.empty, %w[key2 val2])
        carrier = { header_key => ' key1  =  val1,  key2=val2 ' }
        extractor.extract(carrier, Context.empty)
        mock_baggage.verify
      end

      it 'ignores properties' do
        mock_baggage.expect(:set_value, OpenTelemetry::Context.empty, %w[key1 val1])
        mock_baggage.expect(:set_value, OpenTelemetry::Context.empty, %w[key2 val2])
        carrier = { header_key => 'key1=val1,key2=val2;prop1=propval1;prop2=propval2' }
        extractor.extract(carrier, Context.empty)
        mock_baggage.verify
      end

      it 'extracts urlencoded entries' do
        mock_baggage.expect(:set_value, OpenTelemetry::Context.empty, %w[key:1 val1,1])
        mock_baggage.expect(:set_value, OpenTelemetry::Context.empty, %w[key:2 val2,2])
        carrier = { header_key => 'key%3A1=val1%2C1,key%3A2=val2%2C2' }
        extractor.extract(carrier, Context.empty)
      end
    end
  end
end
