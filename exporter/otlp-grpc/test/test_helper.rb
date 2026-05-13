# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'simplecov'
require 'pry'

require 'opentelemetry-test-helpers'
require 'opentelemetry/exporter/otlp/grpc'
require 'minitest/autorun'
require 'webmock/minitest'

OpenTelemetry.logger = Logger.new(File::NULL)
