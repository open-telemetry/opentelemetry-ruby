# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'opentelemetry'
require 'opentelemetry-instrumentation-base'

module OpenTelemetry
  module Instrumentation
    # Contains the OpenTelemetry instrumentation for the ActiveJob gem
    module ActiveJob
    end
  end
end

require_relative './active_job/instrumentation'
require_relative './active_job/version'
