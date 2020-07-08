# frozen_string_literal: true

# Copyright 2020 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  # Instrumentation should be able to handle the case when the library is not installed on a user's system.
  module Snstrumentations
  end
end

require_relative './instrumentation/rack'
