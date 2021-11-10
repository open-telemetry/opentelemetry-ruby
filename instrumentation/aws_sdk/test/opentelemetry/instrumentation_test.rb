# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::Instrumentation::AwsSdk do
  let(:instrumentation) { OpenTelemetry::Instrumentation::AwsSdk::Instrumentation.instance }
  let(:minimum_version) { OpenTelemetry::Instrumentation::AwsSdk::Instrumentation::MINIMUM_VERSION }
  let(:exporter) { EXPORTER }
  let(:last_span) { exporter.finished_spans.last }

  it 'has #name' do
    _(instrumentation.name).must_equal 'OpenTelemetry::Instrumentation::AwsSdk'
  end

  it 'has #version' do
    _(instrumentation.version).wont_be_nil
    _(instrumentation.version).wont_be_empty
  end

  describe '#compatible' do
    it 'returns false for unsupported gem versions' do
      Gem.stub(:loaded_specs, 'aws-sdk' => Gem::Specification.new { |s| s.version = '1.0.0' }) do
        _(instrumentation.compatible?).must_equal false
      end
    end

    it 'returns true for supported gem versions' do
      Gem.stub(:loaded_specs, 'aws-sdk' => Gem::Specification.new { |s| s.version = minimum_version }) do
        _(instrumentation.compatible?).must_equal true
      end
    end
  end

  describe '#install' do
    it 'accepts argument' do
      _(instrumentation.install({})).must_equal(true)
      instrumentation.instance_variable_set(:@installed, false)
    end
  end

  describe 'validate_spans' do
    describe 'SNS' do
      it 'should have correct attributes' do
        sns = Aws::SNS::Client.new(stub_responses: true)
        sns.stub_responses(:publish)

        sns.publish message: 'msg'

        _(last_span.attributes['rpc.system']).must_equal 'aws-api'
        _(last_span.attributes['rpc.service']).must_equal 'SNS'
        _(last_span.attributes['rpc.method']).must_equal 'Publish'
        _(last_span.attributes['aws.region']).must_equal 'us-stubbed-1'
        _(last_span.status.code).must_equal OpenTelemetry::Trace::Status::UNSET
      end

      # TODO add error test
    end

    describe 'S3' do
      it 'should have correct attributes when success' do
        sns = Aws::S3::Client.new(stub_responses: { list_buckets: { buckets: [{ name: 'bucket1' }] } })

        sns.list_buckets

        _(last_span.attributes['rpc.system']).must_equal 'aws-api'
        _(last_span.attributes['rpc.service']).must_equal 'S3'
        _(last_span.attributes['rpc.method']).must_equal 'ListBuckets'
        _(last_span.attributes['aws.region']).must_equal 'us-stubbed-1'
        _(last_span.status.code).must_equal OpenTelemetry::Trace::Status::UNSET
      end

      it 'should have correct attributes when error' do
        sns = Aws::S3::Client.new(stub_responses: { list_buckets: 'NotFound' })
        ignore_exception {
          sns.list_buckets
        }

        _(last_span.attributes['rpc.system']).must_equal 'aws-api'
        _(last_span.attributes['rpc.service']).must_equal 'S3'
        _(last_span.attributes['rpc.method']).must_equal 'ListBuckets'
        _(last_span.attributes['aws.region']).must_equal 'us-stubbed-1'
        _(last_span.status.code).must_equal OpenTelemetry::Trace::Status::ERROR
      end
    end
  end
end
