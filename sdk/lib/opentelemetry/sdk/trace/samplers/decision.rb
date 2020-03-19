# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module SDK
    module Trace
      module Samplers
        # The Decision module contains a set of constants to be used in the
        # decision part of a sampling {Result}.
        module Decision
          # Decision to not record events and not sample.
          NOT_RECORD = :__not_record__

          # Decision to record events and not sample.
          RECORD = :__record__

          # Decision to record events and sample.
          RECORD_AND_SAMPLED = :__record_and_sampled__
        end
      end
    end
  end
end
