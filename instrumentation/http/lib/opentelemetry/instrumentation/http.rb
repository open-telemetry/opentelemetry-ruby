# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'opentelemetry'

module OpenTelemetry
  module Instrumentation
    # Contains the OpenTelemetry instrumentation for the Http gem
    module Http
    end
  end
end

require_relative './http/instrumentation'
require_relative './http/version'
