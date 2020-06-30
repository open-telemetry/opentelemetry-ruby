# frozen_string_literal: true

# Copyright 2020 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'opentelemetry'

module OpenTelemetry
  module Instrumentation
    # Contains the OpenTelemetry instrumentation for the Ethon gem
    module Ethon
    end
  end
end

require_relative './ethon/instrumentation'
require_relative './ethon/version'
