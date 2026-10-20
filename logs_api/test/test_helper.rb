# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'dotenv'
Dotenv.load(File.expand_path('.env', __dir__))

require 'simplecov'
SimpleCov.start

require 'opentelemetry-logs-api'
require 'minitest/autorun'
