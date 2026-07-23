# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
# SPDX-License-Identifier: Apache-2.0

require_relative 'generated_constants'

RubySDK = Struct.new(
  :tracer_provider,
  :meter_provider,
  :logger_provider,
  :resource,
  :propagator
)
