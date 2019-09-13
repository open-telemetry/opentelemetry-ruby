# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module SDK
    module Trace
      module Samplers
        # The Decision class represents an arbitrary sampling decision. It can
        # have a boolean value as a sampling decision and a collection of
        # attributes to be attached to a sampled root span.
        module Decision
          # Decision to not record events and not propagate.
          NOT_RECORD = :__not_record__

          # Decision to record events and not propagate.
          RECORD = :__record__

          # Decision to record events and propagate.
          RECORD_AND_PROPAGATE = :__record_and_propagate__
        end
      end
    end
  end
end
