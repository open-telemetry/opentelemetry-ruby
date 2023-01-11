# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

if RUBY_ENGINE == 'ruby'
  require 'simplecov'
  SimpleCov.start
end

require 'opentelemetry/sdk'
require 'opentelemetry-test-helpers'
require 'opentelemetry-exporter-otlp-common'

require 'minitest/autorun'
require 'webmock/minitest'

require 'pry'

OpenTelemetry.logger = Logger.new(File::NULL)
