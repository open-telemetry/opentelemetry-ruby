# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'opentelemetry'
require 'opentelemetry/common'
require 'opentelemetry-instrumentation-base'

module OpenTelemetry
  module Instrumentation
    # Contains the OpenTelemetry instrumentation for the Redis gem
    module Redis
      extend OpenTelemetry::Common::AttributePropagation
    end
  end
end

require_relative './redis/instrumentation'
require_relative './redis/version'
