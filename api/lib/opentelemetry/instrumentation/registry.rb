# frozen_string_literal: true

# Copyright 2020 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Instrumentation
    # The instrumentation Registry contains information about instrumentation
    # adapters available and facilitates discovery, installation and
    # configuration. This functionality is primarily useful for SDK
    # implementors.
    class Registry
      def initialize
        @lock = Mutex.new
        @adapters = []
      end

      # @api private
      def register(adapter)
        @lock.synchronize do
          @adapters << adapter
        end
      end

      # Lookup an adapter definition by name. Returns nil if +adapter_name+
      # is not found.
      #
      # @param [String] adapter_name A stringified class name for an adapter
      # @return [Adapter]
      def lookup(adapter_name)
        @lock.synchronize do
          find_adapter(adapter_name)
        end
      end

      # Install the specified adapters with optionally specified configuration.
      #
      # @param [Array<String>] adapter_names An array of adapter names to
      #   install
      # @param [optional Hash<String, Hash>] adapter_config_map A map of
      #   adapter_name to config. This argument is optional and config can be
      #   passed for as many or as few adapters as desired.
      def install(adapter_names, adapter_config_map = {})
        @lock.synchronize do
          adapter_names.each do |adapter_name|
            adapter = find_adapter(adapter_name)
            OpenTelemetry.logger.warn "Could not install #{adapter_name} because it was not found" unless adapter

            install_adapter(adapter, adapter_config_map[adapter.name])
          end
        end
      end

      # Install all instrumentation available and installable in this process.
      #
      # @param [optional Hash<String, Hash>] adapter_config_map A map of
      #   adapter_name to config. This argument is optional and config can be
      #   passed for as many or as few adapters as desired.
      def install_all(adapter_config_map = {})
        @lock.synchronize do
          @adapters.map(&:instance).each do |adapter|
            install_adapter(adapter, adapter_config_map[adapter.name])
          end
        end
      end

      private

      def find_adapter(adapter_name)
        @adapters.detect { |a| a.instance.name == adapter_name }
                   &.instance
      end

      def install_adapter(adapter, config)
        if adapter.install(config)
          OpenTelemetry.logger.info "Adapter: #{adapter.name} was successfully installed"
        else
          OpenTelemetry.logger.warn "Adapter: #{adapter.name} failed to install"
        end
      rescue => e # rubocop:disable Style/RescueStandardError
        OpenTelemetry.logger.warn "Adapter: #{adapter.name} unhandled exception" \
                                  "during install #{e}: #{e.backtrace}"
      end
    end
  end
end
