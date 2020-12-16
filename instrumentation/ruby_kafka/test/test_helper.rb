# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'active_support'
require 'kafka'

require 'opentelemetry/sdk'

require 'pry'
require 'minitest/autorun'

# ruby-kafka 1.1.0 depends on active support `.try`
# https://github.com/zendesk/ruby-kafka/issues/836
require 'active_support/core_ext/object/try' if Gem.loaded_specs['ruby-kafka'].version == Gem::Version.new('1.1.0')

# global opentelemetry-sdk setup:
EXPORTER = OpenTelemetry::SDK::Trace::Export::InMemorySpanExporter.new
SPAN_PROCESSOR = OpenTelemetry::SDK::Trace::Export::SimpleSpanProcessor.new(EXPORTER)

OpenTelemetry::SDK.configure do |c|
  c.add_span_processor SPAN_PROCESSOR
end

def clear_notification_subscriptions
  OpenTelemetry::Instrumentation::RubyKafka::Events::ALL.each do |event|
    ActiveSupport::Notifications.unsubscribe(event::EVENT_NAME)
  end
end

def wait_for(max_attempts: 10, retry_delay: 0.10, error_message:)
  attempts = 0
  while attempts < max_attempts
    return if yield

    attempts += 1
    raise error_message if attempts >= max_attempts

    sleep retry_delay
  end
end
