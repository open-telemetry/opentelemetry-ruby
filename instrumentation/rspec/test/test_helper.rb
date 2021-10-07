# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0
require 'opentelemetry/sdk'

require 'rspec/core/dsl'
module RSpec
  module Core
    module DSL
      def self.change_global_dsl(&blk)
        nil
      end
    end
  end
end
require 'rspec/core'

require 'minitest/autorun'
require 'webmock/minitest'

# global opentelemetry-sdk setup:
EXPORTER = OpenTelemetry::SDK::Trace::Export::InMemorySpanExporter.new
span_processor = OpenTelemetry::SDK::Trace::Export::SimpleSpanProcessor.new(EXPORTER)

OpenTelemetry::SDK.configure do |c|
  c.add_span_processor span_processor
end
