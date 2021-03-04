# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path('../lib', __dir__)
require 'opentelemetry/sdk'
require 'opentelemetry/propagator/ottrace'
require 'minitest/autorun'
