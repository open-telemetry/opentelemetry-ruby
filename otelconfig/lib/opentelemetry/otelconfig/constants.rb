# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
# SPDX-License-Identifier: Apache-2.0

RubySDK = Struct.new(
  :tracer_provider,
  :meter_provider,
  :logger_provider,
  :resource,
  :propagator
)
