# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'opentelemetry-sdk'
require 'opentelemetry-test-helpers'
require 'minitest/autorun'
require 'pry'

require 'simplecov' if RUBY_ENGINE == "ruby"
SimpleCov.start
SimpleCov.minimum_coverage 85
