# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require_relative '../../../test_helper'

require_relative '../../../../lib/opentelemetry/instrumentation/ruby_kafka/utils'

describe OpenTelemetry::Instrumentation::RubyKafka::Utils do
  it 'returns input as itself if it is valid utf_8' do
    input = 'foobarbaz'
    _(OpenTelemetry::Instrumentation::RubyKafka::Utils.extract_message_key(input).object_id).must_equal(input.object_id)
  end

  it 'returns input utf_8 encoded if it is encoded differently but not encoded' do
    input = String.new('foobarbaz', encoding: 'ASCII-8BIT')
    _(OpenTelemetry::Instrumentation::RubyKafka::Utils.extract_message_key(input)).must_equal('foobarbaz')
    _(OpenTelemetry::Instrumentation::RubyKafka::Utils.extract_message_key(input).encoding).must_equal(Encoding::UTF_8)
  end

  it 'returns input as a hexstring if it is not valid utf_8' do
    input = String.new("\x00\x00\x00\x00\x00\xAC\xBA\xC4", encoding: 'ASCII-8BIT')
    _(OpenTelemetry::Instrumentation::RubyKafka::Utils.extract_message_key(input)).must_be_nil
  end
end
