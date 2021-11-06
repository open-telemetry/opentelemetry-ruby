# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'simplecov'
SimpleCov.start

require 'opentelemetry/common/test_helpers'
require 'opentelemetry/exporter/otlp'
require 'minitest/autorun'
require 'webmock/minitest'

OpenTelemetry.logger = Logger.new(File::NULL)
