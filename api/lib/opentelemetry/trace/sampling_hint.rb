# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Trace
    # Hints to influence sampling decisions. The default option for span
    # creation is to not provide any suggestion.
    module SamplingHint
      # Suggest to not record events and not sample.
      NOT_RECORD = :__not_record__

      # Suggest to record events and not sample.
      RECORD = :__record__

      # Suggest to record events and sample.
      RECORD_AND_SAMPLED = :__record_and_sampled__
    end
  end
end
