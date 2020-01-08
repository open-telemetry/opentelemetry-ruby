# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Instrumentation
    # The Adapter class holds all metadata and configuration for an
    # instrumentation adapter. All instrumentation adapter packages should
    # include a subclass of +Instrumentation::Adapter+ that will register
    # it with +OpenTelemetry.instrumentation_registry+ and make it available for
    # discovery and installation by an SDK.
    #
    # A typical subclass of Adapter will provide the adapter_name,
    # adapter_version, an install block, a present block, and possibly
    # a compatible block. Below is an example:
    #
    # module OpenTelemetry
    #   module Adapters
    #     module Sinatra
    #       class Adapter < OpenTelemetry::Instrumentation::Adapter
    #         adapter_name 'OpenTelemetry::Adapters::Sinatra'
    #         adapter_version OpenTelemetry::Adapters::Sinatra::VERSION
    #
    #         install do |config|
    #           # install instrumentation, either by library hook or applying
    #           # a monkey patch
    #         end
    #
    #         # determine if the target library is present
    #         present do
    #           Gem.loaded_specs.key?('sinatra')
    #         end
    #
    #         # if the target library is present, is it compatible?
    #         compatible do
    #           Gem.loaded_specs['sinatra'].version > MIN_VERSION
    #         end
    #       end
    #     end
    #   end
    # end
    #
    # All subclasses of OpenTelemetry::Instrumentation::Adapter are automatically
    # registered with OpenTelemetry.instrumentation_registry which is used by
    # SDKs for for instrumentation discovery and installation.
    #
    # Instrumentation libraries can use the adapter subclass to easily gain
    # a reference to its named tracer. For example:
    #
    # OpenTelemetry::Adapters::Sintatra.instance.tracer
    #
    # The adapter class establishes a convention for disabling an adapter
    # by environment variable and local configuration. An adapter disabled
    # by environment variable will take precedence over local config. The
    # convention for environment variable name is the library name, upcased with
    # '::' replaced by underscores, and '_ENABLED' appended. For example:
    # OPENTELEMETRY_ADAPTERS_SINATRA_ENABLED = false.
    class Adapter
      class << self
        private :new # rubocop:disable Style/AccessModifierDeclarations

        def inherited(subclass)
          OpenTelemetry.instrumentation_registry.register(subclass)
        end

        # The name of this instrumentation adapter. Typically this is going
        # to be the name of the instrumentation package. For example,
        # 'OpenTelemetry::Adapters::Sinatra'
        #
        # @param [String] adapter_name The full name of the adapter package
        def adapter_name(adapter_name = nil)
          if adapter_name
            @adapter_name = adapter_name
          else
            @adapter_name ||= name
          end
        end

        # The version of this adapter. Typically this will be the package
        # version of the adapter. For example,
        # OpenTelemetry::Adapters::Sintra::VERSION
        #
        # @param [String] adapter_version The version of the adapter package
        def adapter_version(adapter_version = nil)
          if adapter_version
            @adapter_version = adapter_version
          else
            @adapter_version ||= '0.0.0'
          end
        end

        # The install block for this adapter. This will be where you install
        # instrumentation, either by framework hook or applying a monkey patch.
        #
        # @param [Callable] blk The install block for this adapter
        # @yieldparam [Hash] config The adapter config will be yielded to the
        #   install block
        def install(&blk)
          @install_blk = blk
        end

        # The present block for this adapter. This block is used to detect if
        # target library is present on the system. Typically this will involve
        # checking to see if the target gem spec was loaded or if expected
        # constants from the target library are present.
        #
        # @param [Callable] blk The present block for this adapter
        def present(&blk)
          @present_blk = blk
        end

        # The compatible block for this adapter. This check will be run if the
        # target library is present to determine if it's compatible. It's not
        # required, but a common use case will be to check to target library
        # version for compatibility.
        #
        # @param [Callable] blk The compatibility block for this adapter
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
      # OPENTELEMETRY_ADAPTERS_SINATRA_ENABLED. A value of 'false' will disable
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
