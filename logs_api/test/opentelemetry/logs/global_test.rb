# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'
require 'opentelemetry/logs/global'

describe 'OpenTelemetry.logger_provider' do
  after do
    OpenTelemetry::Internal.logger_provider = OpenTelemetry::Internal::ProxyLoggerProvider.new
  end

  it 'reads the provider held in the internal slot' do
    provider = OpenTelemetry::Logs::LoggerProvider.new
    OpenTelemetry::Internal.logger_provider = provider

    _(OpenTelemetry.logger_provider).must_equal(provider)
  end

  it 'writes through to the internal slot' do
    provider = OpenTelemetry::Logs::LoggerProvider.new
    OpenTelemetry.logger_provider = provider

    _(OpenTelemetry::Internal.logger_provider).must_equal(provider)
  end

  it 'can be required after a provider is already registered' do
    provider = OpenTelemetry::Logs::LoggerProvider.new
    OpenTelemetry::Internal.logger_provider = provider
    require 'opentelemetry/logs/global'

    _(OpenTelemetry.logger_provider).must_equal(provider)
  end
end
