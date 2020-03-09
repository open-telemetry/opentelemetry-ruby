# frozen_string_literal: true

# Copyright 2020 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'opentelemetry'

module OpenTelemetry
  module Adapters
    # Contains the OpenTelemetry adapter for the Rack gem
    module Rack
    end
  end
end

require_relative './rack/adapter'
require_relative './rack/version'
