# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'opentelemetry/context/propagation/composite_propagator'
require 'opentelemetry/context/propagation/default_setter'
require 'opentelemetry/context/propagation/noop_extractor'
require 'opentelemetry/context/propagation/noop_injector'
require 'opentelemetry/context/propagation/propagation'
require 'opentelemetry/context/propagation/propagator'
require 'opentelemetry/context/propagation/text_map_getter'
require 'opentelemetry/context/propagation/rack_env_getter'

module OpenTelemetry
  class Context
    # The propagation module contains APIs and utilities to interact with context
    # and propagate across process boundaries.
    module Propagation
      extend self

      TEXT_MAP_GETTER = TextMapGetter.new
      RACK_ENV_GETTER = RackEnvGetter.new

      private_constant :TEXT_MAP_GETTER, :RACK_ENV_GETTER

      # Returns a {TextMapGetter} instance suitable for reading values from a
      # hash-like carrier
      def text_map_getter
        TEXT_MAP_GETTER
      end

      # Returns a {RackEnvGetter} instance suitable for reading values from a
      # Rack environment.
      def rack_env_getter
        RACK_ENV_GETTER
      end
    end
  end
end
