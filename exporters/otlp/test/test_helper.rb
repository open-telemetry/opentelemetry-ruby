# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'simplecov'
SimpleCov.start

require 'opentelemetry/exporters/otlp'
require 'minitest/autorun'
require 'webmock/minitest'
require 'byebug'

OpenTelemetry.logger = Logger.new('/dev/null')
