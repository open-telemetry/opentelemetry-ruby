# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'opentelemetry'

module OpenTelemetry
  # SDK provides the reference implementation of the OpenTelemetry API.
  module SDK
  end
end

require 'opentelemetry/sdk/internal'
require 'opentelemetry/sdk/trace'
require 'opentelemetry/sdk/version'
