# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

# Installs the top-level meter provider accessors on behalf of metrics SDKs
# released before those accessors moved out of this gem. Those versions assign
# and read +OpenTelemetry.meter_provider+ while configuring and after forking,
# and have no way to require +opentelemetry/metrics/global+ themselves.
#
# Such an SDK is always loaded by the time it reaches for the accessor, so the
# check cannot happen at require time. It happens on the miss instead.
#
# Removal is tracked in #2414.
module OpenTelemetry
  module Metrics
    # Detects a metrics SDK that predates {OpenTelemetry::Metrics::Global} and
    # installs the accessors it expects. With no SDK loaded, +super+ raises
    # NoMethodError, which is what a caller holding only the API is meant to
    # get.
    #
    # @api private
    module LegacyGlobalCompat
      ACCESSORS = %i[meter_provider meter_provider=].freeze

      WARNING = 'opentelemetry-metrics-sdk 0.18.0 and earlier register the global meter ' \
                'provider through a compatibility shim in opentelemetry-metrics-api. ' \
                'Upgrade to opentelemetry-metrics-sdk 0.19.0 or later.'

      # Keyed on MeterProvider rather than the SDK's Metrics namespace, which
      # another gem could plausibly define without the SDK being present.
      def self.handles?(name)
        ACCESSORS.include?(name) && defined?(OpenTelemetry::SDK::Metrics::MeterProvider)
      end

      private

      def method_missing(name, *, &)
        return super unless LegacyGlobalCompat.handles?(name)

        require 'opentelemetry/metrics/global'
        return super unless singleton_class.method_defined?(name)

        OpenTelemetry.logger.warn(WARNING)
        public_send(name, *, &)
      end

      def respond_to_missing?(name, include_private = false)
        LegacyGlobalCompat.handles?(name) || super
      end
    end
  end

  singleton_class.prepend(Metrics::LegacyGlobalCompat)
end
