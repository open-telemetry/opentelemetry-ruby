# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Instrumentation
    # The instrumentation Registry contains information about instrumentation
    # adapters available and facilitates their installation and configuration.
    class Registry
      def initialize
        @lock = Mutex.new
        @adapters = []
      end

      def register(adapter)
        @lock.synchronize do
          @adapters << adapter
        end
      end

      def lookup(adapter_name)
        @lock.synchronize do
          find_adapter(adapter_name)
        end
      end

      def install(adapter_names, adapter_config_map = {})
        @lock.synchronize do
          adapter_names.each do |adapter_name|
            adapter = find_adapter(adapter_name)
            OpenTelemetry.logger.warn "Could not install #{adapter_name} because it was not found" unless adapter

            install_adapter(adapter, adapter_config_map[adapter.name])
          end
        end
      end

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
      end
    end
  end
end
