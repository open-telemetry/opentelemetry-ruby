# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'opentelemetry'
require 'opentelemetry-instrumentation-base'

module OpenTelemetry
  module Instrumentation
    # Contains the OpenTelemetry instrumentation for the Rails gem
    module Rails
    end
  end
end

require 'opentelemetry-instrumentation-rack'
require_relative './rails/instrumentation'
require_relative './rails/version'
