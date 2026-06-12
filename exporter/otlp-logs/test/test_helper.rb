# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'simplecov'
require 'opentelemetry-test-helpers'
require 'opentelemetry/exporter/otlp_logs'
require 'minitest/autorun'
require 'webmock/minitest'
require 'minitest/stub_const'

OpenTelemetry.logger = Logger.new(File::NULL)
