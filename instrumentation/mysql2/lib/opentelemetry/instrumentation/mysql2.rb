# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'opentelemetry'
require 'opentelemetry-instrumentation-base'

module OpenTelemetry
  module Instrumentation
    # Contains the OpenTelemetry instrumentation for the Mysql2 gem
    module Mysql2
    end
  end
end

require_relative './mysql2/instrumentation'
require_relative './mysql2/version'
