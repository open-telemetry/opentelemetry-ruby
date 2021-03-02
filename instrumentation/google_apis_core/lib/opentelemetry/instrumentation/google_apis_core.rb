# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'opentelemetry'

module OpenTelemetry
  module Instrumentation
    # Contains the OpenTelemetry instrumentation for the GoogleApisCore gem
    module GoogleApisCore
    end
  end
end

require_relative './google_apis_core/instrumentation'
require_relative './google_apis_core/version'
