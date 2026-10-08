# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'opentelemetry-metrics-api'

# Defines the top-level accessors for the global meter provider. The Metrics
# API is unstable, so requiring +opentelemetry-metrics-api+ does not define
# these. Requiring +opentelemetry-metrics-sdk+ does.
#
# These are delegators. The provider itself lives in
# {OpenTelemetry::Internal}, so this file can be required at any point,
# before or after the SDK is configured.
module OpenTelemetry
  # Register the global meter provider.
  #
  # @param [MeterProvider] provider A meter provider to register as the
  #   global instance.
  def meter_provider=(provider)
    Internal.meter_provider = provider
  end

  # @return [Object, Metrics::MeterProvider] registered meter provider or a
  #   default no-op implementation of the meter provider.
  def meter_provider
    Internal.meter_provider
  end
end
