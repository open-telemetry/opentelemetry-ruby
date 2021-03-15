# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'opentelemetry/baggage/propagation'
require 'opentelemetry/baggage/builder'
require 'opentelemetry/baggage/entry'
require 'opentelemetry/baggage/manager'
require 'opentelemetry/baggage/noop_builder'
require 'opentelemetry/baggage/noop_manager'

module OpenTelemetry
  # The Baggage module provides functionality to record and propagate
  # baggage in a distributed trace
  module Baggage
  end
end
