# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'simplecov'
SimpleCov.start

require 'opentelemetry-test-helpers'
require 'opentelemetry-exporter-otlp-http'
require 'minitest/autorun'
require 'webmock/minitest'
require 'pry'

OpenTelemetry.logger = Logger.new(File::NULL)
