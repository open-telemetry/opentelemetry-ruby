# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'opentelemetry/trace/propagation/binary_format'
require 'opentelemetry/trace/propagation/trace_parent'
require 'opentelemetry/trace/propagation/text_format'
require 'opentelemetry/trace/propagation/context_keys'

module OpenTelemetry
  module Trace
    # The Trace::Propagation module contains injectors and extractors for
    # sending and receiving span context over the wire
    module Propagation
    end
  end
end
