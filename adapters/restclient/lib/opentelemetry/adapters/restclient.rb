# frozen_string_literal: true

# Copyright 2020 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'opentelemetry'

module OpenTelemetry
  module Adapters
    # Contains the OpenTelemetry adapter for the RestClient gem
    module RestClient
    end
  end
end

require_relative './restclient/adapter'
require_relative './restclient/version'
