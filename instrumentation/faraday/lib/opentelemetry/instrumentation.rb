# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  # "Instrumentation instrumentations" are specified by
  # https://github.com/open-telemetry/opentelemetry-specification/blob/57714f7547fe4dcb342ad0ad10a80d86118431c7/specification/overview.md#instrumentation-adapters
  #
  # Instrumentation should be able to handle the case when the library is not installed on a user's system.
  module Instrumentation
  end
end

require_relative './instrumentation/faraday'
