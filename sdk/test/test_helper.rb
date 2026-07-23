# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'dotenv'
Dotenv.load(File.expand_path('.env', __dir__))

require 'simplecov'
SimpleCov.start

require 'opentelemetry-test-helpers'
require 'opentelemetry-sdk'
require 'opentelemetry-instrumentation-base'
require 'minitest/autorun'

OpenTelemetry.logger = Logger.new(File::NULL)

SpanLimits = OpenTelemetry::SDK::Trace::SpanLimits
