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
          NOT_RECORD = OpenTelemetry::Trace::SamplingHint::NOT_RECORD

          # Decision to record events and not sample.
          RECORD = OpenTelemetry::Trace::SamplingHint::RECORD

          # Decision to record events and sample.
          RECORD_AND_SAMPLED = OpenTelemetry::Trace::SamplingHint::RECORD_AND_SAMPLED
        end
      end
    end
  end
end
