# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'simplecov'
SimpleCov.start
SimpleCov.minimum_coverage 85

require 'opentelemetry/sdk'
require 'minitest/autorun'

OpenTelemetry.logger = Logger.new('/dev/null')
