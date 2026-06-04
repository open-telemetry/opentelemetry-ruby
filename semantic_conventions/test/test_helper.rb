# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'simplecov'
require 'minitest/autorun'

Dir[File.join(File.dirname(__FILE__), '..', 'lib', 'opentelemetry', '**', '*.rb')].each { |file| require file }
