# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

# require 'simplecov'
# # SimpleCov.start
# # SimpleCov.minimum_coverage 85

require 'opentelemetry-metrics-sdk'
require 'minitest/autorun'
require 'pry'

OpenTelemetry.logger = Logger.new(File::NULL)
