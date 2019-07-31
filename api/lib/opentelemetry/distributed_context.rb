# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'opentelemetry/distributed_context/distributed_context'
require 'opentelemetry/distributed_context/entry'
require 'opentelemetry/distributed_context/manager'
require 'opentelemetry/distributed_context/propagation'

module OpenTelemetry
  # DistributedContext is an abstract data type that represents a collection of entries. Each key of a DistributedContext is
  # associated with exactly one value. DistributedContext is serializable, to facilitate propagating it not only inside the
  # process but also across process boundaries. DistributedContext is used to annotate telemetry with the name:value pair
  # Entry. Those values can be used to add dimensions to the metric or additional context properties to logs and traces.
  module DistributedContext
  end
end
