# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'opentelemetry/distributed_context/propagation/context_keys'
require 'opentelemetry/distributed_context/propagation/http_injector'
require 'opentelemetry/distributed_context/propagation/http_extractor'

module OpenTelemetry
  module DistributedContext
    # The DistributedContext::Propagation module contains injectors and
    # extractors for sending and receiving correlation context over the wire
    module Propagation
    end
  end
end
