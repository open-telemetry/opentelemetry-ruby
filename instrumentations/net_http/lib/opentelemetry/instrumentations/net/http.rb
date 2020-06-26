# frozen_string_literal: true

# Copyright 2020 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'opentelemetry'

module OpenTelemetry
  module Instrumentations
    module Net
      # Contains the OpenTelemetry instrumentation for the Net::HTTP gem
      module HTTP
      end
    end
  end
end

require_relative './http/instrumentation'
require_relative './http/version'
