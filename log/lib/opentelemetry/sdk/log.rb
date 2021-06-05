# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  def log_emitter_provider=(log_emitter_provider)
    @log_emitter_provider = log_emitter_provider
  end

  def log_emitter_provider
    @log_emitter_provider
  end

  module SDK
    # The Log module contains the OpenTelemetry logging reference
    # implementation.
    module Log
    end
  end
end

require 'opentelemetry/sdk/log/configurator'
require 'opentelemetry/sdk/log/export'
require 'opentelemetry/sdk/log/log_data'
require 'opentelemetry/sdk/log/log_emitter'
require 'opentelemetry/sdk/log/log_emitter_provider'
require 'opentelemetry/sdk/log/log_record'
require 'opentelemetry/sdk/log/multi_log_processor'
require 'opentelemetry/sdk/log/noop_log_processor'
