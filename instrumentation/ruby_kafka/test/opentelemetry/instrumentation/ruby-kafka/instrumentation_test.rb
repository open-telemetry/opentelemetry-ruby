# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

require_relative '../../../../lib/opentelemetry/instrumentation/ruby_kafka'

describe OpenTelemetry::Instrumentation::RubyKafka::Instrumentation do
  let(:instrumentation) { OpenTelemetry::Instrumentation::RubyKafka::Instrumentation.instance }

  it 'has #name' do
    _(instrumentation.name).must_equal 'OpenTelemetry::Instrumentation::RubyKafka'
  end

  it 'has #version' do
    _(instrumentation.version).wont_be_nil
    _(instrumentation.version).wont_be_empty
  end

  describe '#install' do
    it 'accepts arguments' do
      instrumentation.instance_variable_set(:@installed, false)
      _(instrumentation.install({})).must_equal(true)
    end

    it 'logs a warning when active support is not available' do
      instrumentation.instance_variable_set(:@installed, false)
      warning_message = 'OpenTelemetry::Instrumentation::RubyKafka requires ActiveSupport::Notifications to generate spans from the ruby-kafka instrumentation.'
      mock_logger = MiniTest::Mock.new
      mock_logger.expect(:warn, nil, [warning_message])

      OpenTelemetry::SDK.configure do |c|
        c.add_span_processor SPAN_PROCESSOR
        c.logger = mock_logger
      end

      @original = ::ActiveSupport::Notifications
      ::ActiveSupport.send(:remove_const, 'Notifications')

      _(instrumentation.install({})).must_equal(true)

      mock_logger.verify
    ensure
      ::ActiveSupport.const_set('Notifications', @original)
    end
  end
end
