# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

# Installs the top-level logger provider accessors on behalf of logs SDKs
# released before those accessors moved out of this gem. Those versions assign
# and read +OpenTelemetry.logger_provider+ while configuring, and have no way
# to require +opentelemetry/logs/global+ themselves.
#
# Such an SDK is always loaded by the time it reaches for the accessor, so the
# check cannot happen at require time. It happens on the miss instead.
#
# Removal is tracked in #2414.
module OpenTelemetry
  module Logs
    # Detects a logs SDK that predates {OpenTelemetry::Logs::Global} and
    # installs the accessors it expects. With no SDK loaded, +super+ raises
    # NoMethodError, which is what a caller holding only the API is meant to
    # get.
    #
    # @api private
    module LegacyGlobalCompat
      ACCESSORS = %i[logger_provider logger_provider=].freeze

      WARNING = 'opentelemetry-logs-sdk 0.6.1 and earlier register the global logger ' \
                'provider through a compatibility shim in opentelemetry-logs-api. ' \
                'Upgrade to opentelemetry-logs-sdk 0.7.0 or later.'

      # Keyed on LoggerProvider rather than the SDK's Logs namespace, which
      # another gem could plausibly define without the SDK being present.
      def self.handles?(name)
        ACCESSORS.include?(name) && defined?(OpenTelemetry::SDK::Logs::LoggerProvider)
      end

      private

      def method_missing(name, *, &)
        return super unless LegacyGlobalCompat.handles?(name)

        require 'opentelemetry/logs/global'
        return super unless singleton_class.method_defined?(name)

        OpenTelemetry.logger.warn(WARNING)
        public_send(name, *, &)
      end

      def respond_to_missing?(name, include_private = false)
        LegacyGlobalCompat.handles?(name) || super
      end
    end
  end

  singleton_class.prepend(Logs::LegacyGlobalCompat)
end
