# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module SDK
    # InstrumentationLibrary is a struct containing library information for export.
    InstrumentationLibrary = Struct.new(:name,
                                        :version)
  end
end
