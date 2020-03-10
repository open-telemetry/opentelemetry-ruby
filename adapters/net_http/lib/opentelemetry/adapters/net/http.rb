# frozen_string_literal: true

# Copyright 2020 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'opentelemetry'

module OpenTelemetry
  module Adapters
    module Net
      # Contains the OpenTelemetry adapter for the Net::HTTP gem
      module HTTP
      end
    end
  end
end

require_relative './http/adapter'
require_relative './http/version'
