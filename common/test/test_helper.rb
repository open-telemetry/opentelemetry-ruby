# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'simplecov' if RUBY_ENGINE == "ruby"
SimpleCov.start

require 'opentelemetry-test-helpers'
require 'opentelemetry/common'
require 'minitest/autorun'
require 'pry'
