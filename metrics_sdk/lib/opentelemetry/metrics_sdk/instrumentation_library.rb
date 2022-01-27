# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module MetricsSDK
    # InstrumentationLibrary is a struct containing library information for export.
    InstrumentationLibrary = Struct.new(:name,
                                        :version)
  end
end
