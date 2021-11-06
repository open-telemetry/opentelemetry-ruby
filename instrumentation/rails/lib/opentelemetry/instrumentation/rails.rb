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

require 'opentelemetry-instrumentation-action_pack'
require 'opentelemetry-instrumentation-active_support'
require 'opentelemetry-instrumentation-action_view'
require 'opentelemetry-instrumentation-active_record'
require_relative './rails/instrumentation'
require_relative './rails/version'
