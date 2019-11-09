# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'opentelemetry/distributed_context/propagation/binary_format'
require 'opentelemetry/distributed_context/propagation/trace_parent'
require 'opentelemetry/distributed_context/propagation/text_format'
require 'opentelemetry/distributed_context/propagation/context_keys'

module OpenTelemetry
  module DistributedContext
    # Propagation API consists of two main formats:
    # - @see BinaryFormat is used to serialize and deserialize a value into a binary representation.
    # - @see TextFormat is used to inject and extract a value as text into carriers that travel in-band across process boundaries.
    module Propagation
    end
  end
end
