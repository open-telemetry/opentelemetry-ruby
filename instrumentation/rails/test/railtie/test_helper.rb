# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

# Configure Rails Environment
ENV['RACK_ENV'] = 'test'
ENV['RAILS_ENV'] = 'test'

require 'opentelemetry/sdk'
require 'opentelemetry-test-helpers'
require_relative '../../test/railtie/dummy/config/environment'
require 'rails/test_help'

require 'simplecov'
SimpleCov.start
