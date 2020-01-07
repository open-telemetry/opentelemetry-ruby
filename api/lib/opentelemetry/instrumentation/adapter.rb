# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Instrumentation
    # The Adapter class holds all metadata and configuration for an
    # instrumentation adapter. All instrumentation adapter packages should
    # include a subclass of +Instrumentation::Adapter+ that will register
    # it with +OpenTelemetry::Instrumentation+ and make it available for
    # installation and configuration.
    class Adapter
      class << self
        private :new # rubocop:disable Style/AccessModifierDeclarations

        def inherited(subclass)
          OpenTelemetry.instrumentation_registry.register(subclass)
        end

        def adapter_name(adapter_name = nil)
          if adapter_name
            @adapter_name = adapter_name
          else
            @adapter_name ||= name
          end
        end

        def adapter_version(adapter_version = nil)
          if adapter_version
            @adapter_version = adapter_version
          else
            @adapter_version ||= '0.0.0'
          end
        end

        def install(&blk)
          @install_blk = blk
        end

        def present(&blk)
          @present_blk = blk
        end

        def compatible(&blk)
          @compatible_blk = blk
        end

        def instance
          @instance ||= new(adapter_name, adapter_version, install_blk,
                            present_blk, compatible_blk)
        end

        private

        attr_reader :install_blk, :present_blk, :compatible_blk
      end

      attr_reader :name, :version, :config, :installed, :tracer

      alias installed? installed

      def initialize(name, version, install_blk, present_blk,
                     compatible_blk)
        @name = name
        @version = version
        @install_blk = install_blk
        @present_blk = present_blk
        @compatible_blk = compatible_blk
        @config = {}
        @installed = false
      end

      # Install adapter with the given config. The present? and compatbile?
      # will be run first, and install will return false if either fail. Will
      # return true if install was completed successfully.
      #
      # @param [Hash] config The config for this adapter
      def install(config = {})
        return true if installed?
        return false unless installable?(config)

        @config = config unless config.nil?
        instance_exec(@config, &@install_blk)
        @tracer ||= OpenTelemetry.tracer_factory.tracer(name, version)
        @installed = true
      end

      # Whether or not this adapter is installable in the current process. Will
      # be true when the adapter defines an install block, it's not disabled
      # by enviroment or config, and the target library present and compatible.
      #
      # @param [Hash] config The config for this adapter
      def installable?(config = {})
        @install_blk && enabled?(config) && present? && compatible?
      end

      # Calls the present block of the Adapter subclasses, if no block is provided
      # it's assumed to be present
      def present?
        return true unless @present_blk

        instance_exec(&@present_blk)
      end

      # Calls the compatible block of the Adapter subclasses, if no block is provided
      # it's assumed to be compatible
      def compatible?
        return true unless @compatible_blk

        instance_exec(&@compatible_blk)
      end

      # Whether this adapter is enabled. It first checks to see if it's enabled
      # by an environment variable and will proceed to check if it's enabled
      # by local config, if given.
      #
      # @param [optional Hash] config The local config
      def enabled?(config = nil)
        return false unless enabled_by_env_var?
        return config[:enabled] if config&.key?(:enabled)

        true
      end

      private

      # Checks to see if this adapter is enabled by env var. By convention, the
      # environment variable will be the adapter name upper cased, with '::'
      # replaced by underscores and _ENABLED appended. For example, the
      # environment variable name for OpenTelemetry::Adapter::Sinatra will be
      # OPENTELEMETRY_ADAPTER_SINATRA_ENABLED. A value of 'false' will disable
      # the adapter, all other values will enable it.
      def enabled_by_env_var?
        var_name = name.dup.tap do |n|
          n.upcase!
          n.gsub!('::', '_')
          n << '_ENABLED'
        end
        ENV[var_name] != 'false'
      end
    end
  end
end
