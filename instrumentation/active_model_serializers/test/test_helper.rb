# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'active_support/all'
require 'active_model_serializers'

require 'opentelemetry/sdk'

require 'minitest/autorun'
require 'rspec/mocks/minitest_integration'
require 'webmock/minitest'

# disable logging
ActiveModelSerializers.logger.level = Logger::Severity::UNKNOWN

# global opentelemetry-sdk setup:
EXPORTER = OpenTelemetry::SDK::Trace::Export::InMemorySpanExporter.new
span_processor = OpenTelemetry::SDK::Trace::Export::SimpleSpanProcessor.new(EXPORTER)

OpenTelemetry::SDK.configure do |c|
  c.add_span_processor span_processor
end

module TestHelper
  class Model < ActiveModelSerializers::Model
    attr_accessor :name
  end

  class ModelSerializer < ActiveModel::Serializer
    attributes :name
  end
end
