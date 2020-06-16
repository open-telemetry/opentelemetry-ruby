# frozen_string_literal: true

# Copyright 2020 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'opentelemetry'

module OpenTelemetry
  module Adapters
    # Contains the OpenTelemetry adapter for the Redis gem
    module Mysql2
    end
  end
end

require_relative './mysql2/adapter'
require_relative './mysql2/version'
