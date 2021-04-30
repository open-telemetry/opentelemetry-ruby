# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'opentelemetry'
require 'opentelemetry/instrumentation/registry'
require 'opentelemetry/instrumentation/base'

module OpenTelemetry
  # The instrumentation module contains functionality to register and install
  # instrumentation
  module Instrumentation
    extend self

    # @return [Registry] registry containing all known
    #  instrumentation
    def registry
      @registry ||= Registry.new
    end
  end
end
