# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'opentelemetry/context/propagation/composite_propagator'
require 'opentelemetry/context/propagation/default_getter'
require 'opentelemetry/context/propagation/default_setter'
require 'opentelemetry/context/propagation/noop_extractor'
require 'opentelemetry/context/propagation/noop_injector'
require 'opentelemetry/context/propagation/propagation'
require 'opentelemetry/context/propagation/propagator'

module OpenTelemetry
  class Context
    # The propagation module contains APIs and utilities to interact with context
    # and propagate across process boundaries.
    module Propagation
    end
  end
end
