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
        _(last_span.attributes['aws.region']).must_include 'stubbed'
        _(last_span.attributes['db.system']).must_be_nil
        _(last_span.status.code).must_equal OpenTelemetry::Trace::Status::UNSET
      end
    end

    describe 'S3' do
      it 'should have correct attributes when success' do
        s3 = Aws::S3::Client.new(stub_responses: { list_buckets: { buckets: [{ name: 'bucket1' }] } })

        s3.list_buckets

        _(last_span.attributes['rpc.system']).must_equal 'aws-api'
        _(last_span.attributes['rpc.service']).must_equal 'S3'
        _(last_span.attributes['rpc.method']).must_equal 'ListBuckets'
        _(last_span.attributes['aws.region']).must_include 'stubbed'
        _(last_span.attributes['db.system']).must_be_nil
        _(last_span.status.code).must_equal OpenTelemetry::Trace::Status::UNSET
      end

      it 'should have correct attributes when error' do
        s3 = Aws::S3::Client.new(stub_responses: true)
        s3.stub_responses(:list_buckets, 'NotFound')

        begin
          s3.list_buckets
        rescue StandardError
          _(last_span.attributes['rpc.system']).must_equal 'aws-api'
          _(last_span.attributes['rpc.service']).must_equal 'S3'
          _(last_span.attributes['rpc.method']).must_equal 'ListBuckets'
          _(last_span.attributes['aws.region']).must_include 'stubbed'
          _(last_span.attributes['db.system']).must_be_nil
        end

        _(last_span.status.code).must_equal OpenTelemetry::Trace::Status::ERROR
      end
    end

    describe 'dynamodb' do
      it 'should have db.system attribute' do
        dynamodb_client = Aws::DynamoDB::Client.new(stub_responses: true)

        dynamodb_client.list_tables

        _(last_span.attributes['rpc.system']).must_equal 'aws-api'
        _(last_span.attributes['db.system']).must_equal 'dynamodb'
      end
    end

    describe 'sqs' do
      it 'should have messaging attributes for send_message' do
        sqs_client = Aws::SQS::Client.new(stub_responses: true)

        sqs_client.send_message message_body: 'msg', queue_url: 'https://sqs.fake.amazonaws.com/1/queue-name'

        _(last_span.attributes['rpc.system']).must_equal 'aws-api'
        _(last_span.attributes['messaging.system']).must_equal 'aws.sqs'
        _(last_span.attributes['messaging.destination_kind']).must_equal 'queue'
        _(last_span.attributes['messaging.destination']).must_equal 'queue-name'
        _(last_span.attributes['messaging.url']).must_equal 'https://sqs.fake.amazonaws.com/1/queue-name'
      end

      it 'should have messaging attributes for send_message_batch' do
        sqs_client = Aws::SQS::Client.new(stub_responses: true)

        entries = [
          {
            id: 'Message1',
            message_body: 'This is the first message.'
          },
          {
            id: 'Message2',
            message_body: 'This is the second message.',
            message_attributes: {
              "attr1": {
                "data_type": 'String',
                "string_value": 'value1'
              }
            }
          }
        ]

        sqs_client.send_message_batch(
          queue_url: 'https://sqs.fake.amazonaws.com/1/queue-name',
          entries: entries
        )

        _(last_span.attributes['rpc.system']).must_equal 'aws-api'
        _(last_span.attributes['messaging.system']).must_equal 'aws.sqs'
        _(last_span.attributes['messaging.destination_kind']).must_equal 'queue'
        _(last_span.attributes['messaging.destination']).must_equal 'queue-name'
        _(last_span.attributes['messaging.url']).must_equal 'https://sqs.fake.amazonaws.com/1/queue-name'
      end
    end

    describe 'sns' do
      it 'should have messaging attributes for publish' do
        sns_client = Aws::SNS::Client.new(stub_responses: true)

        sns_client.publish message: 'msg', topic_arn: 'arn:aws:sns:fake:123:topic-name'

        _(last_span.attributes['rpc.system']).must_equal 'aws-api'
        _(last_span.attributes['messaging.system']).must_equal 'aws.sns'
        _(last_span.attributes['messaging.destination_kind']).must_equal 'topic'
        _(last_span.attributes['messaging.destination']).must_equal 'topic-name'
      end

      it 'should handle phone numbers' do
        # skip if using aws-sdk version before phone_number supported (v2.3.18)
        return if Gem::Version.new('2.3.18') > instrumentation.gem_version

        sns_client = Aws::SNS::Client.new(stub_responses: true)

        sns_client.publish message: 'msg', phone_number: '123456'

        _(last_span.attributes['messaging.destination']).must_equal 'phone_number'
        _(last_span.name).must_equal 'phone_number send'
      end
    end
  end

  describe 'MessageAttributeSetter' do
    it 'set when hash length is lower than 10' do
      key = 'foo'
      value = 'bar'
      metadata_attributes = {}
      OpenTelemetry::Instrumentation::AwsSdk::MessageAttributeSetter.set(metadata_attributes, key, value)
      _(metadata_attributes[key]).must_equal(string_value: value, data_type: 'String')
    end

    it 'should keep existing attributes' do
      key = 'foo'
      value = 'bar'
      metadata_attributes = {
        'existingKey' => { string_value: 'existingValue', data_type: 'String' }
      }
      OpenTelemetry::Instrumentation::AwsSdk::MessageAttributeSetter.set(metadata_attributes, key, value)
      _(metadata_attributes[key]).must_equal(string_value: value, data_type: 'String')
      _(metadata_attributes['existingKey']).must_equal(string_value: 'existingValue', data_type: 'String')
    end

    it 'should not add if there are 10 or more existing attributes' do
      metadata_attributes = {
        'existingKey0' => { string_value: 'existingValue', data_type: 'String' },
        'existingKey1' => { string_value: 'existingValue', data_type: 'String' },
        'existingKey2' => { string_value: 'existingValue', data_type: 'String' },
        'existingKey3' => { string_value: 'existingValue', data_type: 'String' },
        'existingKey4' => { string_value: 'existingValue', data_type: 'String' },
        'existingKey5' => { string_value: 'existingValue', data_type: 'String' },
        'existingKey6' => { string_value: 'existingValue', data_type: 'String' },
        'existingKey7' => { string_value: 'existingValue', data_type: 'String' },
        'existingKey8' => { string_value: 'existingValue', data_type: 'String' },
        'existingKey9' => { string_value: 'existingValue', data_type: 'String' }
      }
      OpenTelemetry::Instrumentation::AwsSdk::MessageAttributeSetter.set(metadata_attributes, 'new10', 'value')
      _(metadata_attributes.keys).must_equal(%w[existingKey0 existingKey1 existingKey2 existingKey3 existingKey4 existingKey5 existingKey6 existingKey7 existingKey8 existingKey9])
    end
  end
end
