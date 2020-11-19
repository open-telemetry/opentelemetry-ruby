# frozen_string_literal: true

# Copyright 2020 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'opentelemetry'

module OpenTelemetry
  module Instrumentation
    # Contains the OpenTelemetry instrumentation for the Mongo gem
    module Mongo
    end
  end
end

require_relative './mongo/instrumentation'
require_relative './mongo/version'
