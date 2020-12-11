# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

require 'rack'
require_relative '../../../../../lib/opentelemetry/instrumentation/rack/util/queue_time'

describe OpenTelemetry::Instrumentation::Rack::Util::QueueTime do
  let(:described_class) { OpenTelemetry::Instrumentation::Rack::Util::QueueTime }

  describe '#get_request_start' do
    let(:request_start) { described_class.get_request_start(env) }

    describe 'given a Rack env with' do
      describe 'milliseconds' do
        describe 'REQUEST_START' do
          let(:env) { { described_class::REQUEST_START => "t=#{expected}" } }
          let(:expected) { 1_512_379_167.574 }
          it { expect(request_start.to_f).must_equal(expected) }

          describe 'but does not start with t=' do
            let(:env) { { described_class::REQUEST_START => expected } }
            it { expect(request_start.to_f).must_equal(expected) }
          end

          describe 'without decimal places' do
            let(:env) { { described_class::REQUEST_START => expected } }
            let(:expected) { 1_512_379_167_574 }
            it { expect(request_start.to_f).must_equal(1_512_379_167.574) }
          end

          describe 'but a malformed expected' do
            let(:expected) { 'foobar' }
            it { _(request_start).must_be_nil }
          end

          describe 'before the start of the acceptable time range' do
            let(:expected) { 999_999_999.000 }
            it { _(request_start).must_be_nil }
          end
        end

        describe 'QUEUE_START' do
          let(:env) { { described_class::QUEUE_START => "t=#{expected}" } }
          let(:expected) { 1_512_379_167.574 }
          it { expect(request_start.to_f).must_equal(expected) }
        end
      end

      describe 'microseconds' do
        describe 'REQUEST_START' do
          let(:env) { { described_class::REQUEST_START => "t=#{expected}" } }
          let(:expected) { 1_570_633_834.463123 }
          it { expect(request_start.to_f).must_equal(expected) }

          describe 'but does not start with t=' do
            let(:env) { { described_class::REQUEST_START => expected } }
            it { expect(request_start.to_f).must_equal(expected) }
          end

          describe 'without decimal places' do
            let(:env) { { described_class::REQUEST_START => expected } }
            let(:expected) { 1_570_633_834_463_123 }
            it { expect(request_start.to_f).must_equal(1_570_633_834.463123) }
          end

          describe 'but a malformed expected' do
            let(:expected) { 'foobar' }
            it { _(request_start).must_be_nil }
          end
        end

        describe 'QUEUE_START' do
          let(:env) { { described_class::QUEUE_START => "t=#{expected}" } }
          let(:expected) { 1_570_633_834.463123 }
          it { expect(request_start.to_f).must_equal(expected) }
        end
      end

      describe 'nothing' do
        let(:env) { {} }
        it { _(request_start).must_be_nil }
      end
    end
  end
end
