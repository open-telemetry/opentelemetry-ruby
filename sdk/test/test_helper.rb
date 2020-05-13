# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'simplecov'
SimpleCov.start
SimpleCov.minimum_coverage 85

require 'opentelemetry/sdk'
require 'minitest/autorun'

OpenTelemetry.logger = Logger.new('/dev/null')

def with_env(new_env)
  env_to_reset = ENV.select { |k, _| new_env.key?(k) }
  keys_to_delete = new_env.keys - ENV.keys
  new_env.each_pair { |k, v| ENV[k] = v }
  yield
  env_to_reset.each_pair { |k, v| ENV[k] = v }
  keys_to_delete.each { |k| ENV.delete(k) }
end
