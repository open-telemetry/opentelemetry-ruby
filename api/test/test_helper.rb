# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'simplecov'
require 'opentelemetry-test-helpers'
require 'opentelemetry'
require 'minitest/autorun'

OpenTelemetry.logger = Logger.new(File::NULL)

Context = OpenTelemetry::Context
