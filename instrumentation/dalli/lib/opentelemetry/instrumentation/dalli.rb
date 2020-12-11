# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'opentelemetry'

module OpenTelemetry
  module Instrumentation
    # Contains the OpenTelemetry instrumentation for the Dalli gem
    module Dalli
    end
  end
end

require_relative './dalli/instrumentation'
require_relative './dalli/version'
