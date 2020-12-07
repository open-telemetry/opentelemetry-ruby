# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'opentelemetry'

module OpenTelemetry
  module Instrumentation
    # Contains the OpenTelemetry instrumentation for the AmazingGem gem
    module AmazingGem
    end
  end
end

require_relative './amazing_gem/instrumentation'
require_relative './amazing_gem/version'
