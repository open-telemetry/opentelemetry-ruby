# frozen_string_literal: true

# Copyright 2020 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'opentelemetry'

module OpenTelemetry
  module Adapters
    module Faraday
    end
  end
end

require_relative './faraday/adapter'
require_relative './faraday/version'
