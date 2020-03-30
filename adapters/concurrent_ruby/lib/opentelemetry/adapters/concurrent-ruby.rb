# frozen_string_literal: true

# Copyright 2020 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'opentelemetry'

module OpenTelemetry
  module Adapters
    # Contains the OpenTelemetry adapter for the ConcurrentRuby gem
    module ConcurrentRuby
    end
  end
end

require_relative './concurrent_ruby/adapter'
require_relative './concurrent_ruby/version'
