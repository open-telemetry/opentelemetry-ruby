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
          OpenTelemetry::Instrumentation.registry.register(subclass)
        end

        def adapter_name(adapter_name = nil)
          adapter_name ? @adapter_name = adapter_name : @adapter_name
        end

        def adapter_version(adapter_version = nil)
          adapter_version ? @adapter_version = adapter_version : @adapter_version
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

      attr_reader :adapter_name, :adapter_version, :config

      def initialize(adapter_name, adapter_version, install_blk, present_blk,
                     compatible_blk)
        @adapter_name = adapter_name
        @adapter_version = adapter_version
        @install_blk = install_blk
        @present_blk = present_blk
        @compatible_blk = compatible_blk
      end

      # Install adapter with the given config. The present? and compatbile?
      # will be run first, and install will return false if either faile. Will
      # return true if install was completed successfully.
      #
      # @param [Hash] config The config for this adapter
      def install(config = {})
        @config = config
        return false unless @install_blk && present? && compatible?

        instance_exec(@config, &@install_blk)
        true
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
    end
  end
end
