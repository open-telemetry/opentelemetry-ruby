# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'simplecov'
require 'opentelemetry-test-helpers'
require 'opentelemetry-sdk'
require 'opentelemetry-instrumentation-base'
require 'minitest/autorun'
require 'pry'

OpenTelemetry.logger = Logger.new(File::NULL)

SpanLimits = OpenTelemetry::SDK::Trace::SpanLimits
