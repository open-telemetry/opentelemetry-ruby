# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

if RUBY_ENGINE == 'ruby'
  require 'simplecov'
  SimpleCov.start
end

require 'opentelemetry-test-helpers'
require 'opentelemetry/common'
require 'minitest/autorun'
require 'pry'
