# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

if RUBY_ENGINE == 'ruby'
  require 'simplecov'
  SimpleCov.start
  SimpleCov.minimum_coverage 85
end

require 'minitest/autorun'
require 'pry'

Dir[File.join(File.dirname(__FILE__), '..', 'lib', 'opentelemetry', '**', '*.rb')].sort.each { |file| require file }
