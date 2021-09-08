# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module InstrumentationHelpers
    # HTTP contains instrumentation helpers for http instrumentation.
    module HTTP
    end
  end
end

require_relative './http/request_attributes'
require_relative './http/instrumentation_options'
