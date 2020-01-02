# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'opentelemetry/instrumentation/registry'
require 'opentelemetry/instrumentation/adapter'

module OpenTelemetry
  # The instrumentation module contains functionality to register and install
  # instrumentation adapters
  module Instrumentation
    extend self

    def registry
      @registry ||= Registry.new
    end
  end
end
