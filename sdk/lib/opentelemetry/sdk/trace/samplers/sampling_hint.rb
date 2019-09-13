# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module SDK
    module Trace
      module Samplers
        # Hints to influence sampling decisions. The default option for span
        # creation is to not provide any suggestion.
        module SamplingHints
          # Suggest to not record events and not propagate.
          NOT_RECORD = :__not_record__

          # Suggest to record events and not propagate.
          RECORD = :__record__

          # Suggest to record events and propagate.
          RECORD_AND_PROPAGATE = :__record_and_propagate__
        end
      end
    end
  end
end
