# frozen_string_literal: true

# Copyright 2020 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  # "Instrumentation instrumentations" are specified by
  # https://github.com/open-telemetry/opentelemetry-specification/blob/784635d01d8690c8f5fcd1f55bdbc8a13cf2f4f2/specification/glossary.md#instrumentation-library
  #
  # Instrumentation should be able to handle the case when the library is not installed on a user's system.
  module Instrumentation
  end
end

require_relative './instrumentation/redis'
