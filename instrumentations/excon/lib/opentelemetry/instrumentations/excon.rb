# frozen_string_literal: true

# Copyright 2020 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'opentelemetry'

module OpenTelemetry
  module Instrumentations
    # Contains the OpenTelemetry instrumentation for the Excon gem
    module Excon
    end
  end
end

require_relative './excon/instrumentation'
require_relative './excon/version'
