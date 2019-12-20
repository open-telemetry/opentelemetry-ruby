# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'opentelemetry/correlation_context/propagation'
require 'opentelemetry/trace/propagation'
require 'opentelemetry/context/propagation/propagation'

module OpenTelemetry
  class Context
    # The propagation module contains APIs and utilities to interact with context
    # and propagate across process boundaries.
    module Propagation
    end
  end
end
