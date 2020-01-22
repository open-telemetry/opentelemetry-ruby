# frozen_string_literal: true

# Copyright 2020 OpenTelemetry Authors
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
    # A typical subclass of Adapter will provide an install block, a present
    # block, and possibly a compatible block. Below is an
    # example:
    #
    # module OpenTelemetry
    #   module Adapters
    #     module Sinatra
    #       class Adapter < OpenTelemetry::Instrumentation::Adapter
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
    # The adapter name and version will be inferred from the namespace of the
    # class. In this example, they'd be 'OpenTelemetry::Adapters::Sinatra' and
    # OpenTelemetry::Adapters::Sinatra::VERSION, but can be explicitly set using
    # the +adapter_name+ and +adapter_version+ methods if necessary.
    #
    # All subclasses of OpenTelemetry::Instrumentation::Adapter are automatically
    # registered with OpenTelemetry.instrumentation_registry which is used by
    # SDKs for instrumentation discovery and installation.
    #
    # Instrumentation libraries can use the adapter subclass to easily gain
    # a reference to its named tracer. For example:
    #
    # OpenTelemetry::Adapters::Sinatra.instance.tracer
    #
    # The adapter class establishes a convention for disabling an adapter
    # by environment variable and local configuration. An adapter disabled
    # by environment variable will take precedence over local config. The
    # convention for environment variable name is the library name, upcased with
    # '::' replaced by underscores, and '_ENABLED' appended. For example:
    # OPENTELEMETRY_ADAPTERS_SINATRA_ENABLED = false.
    class Adapter
      class << self
        NAME_REGEX = /^(?:(?<namespace>[a-zA-Z0-9_:]+):{2})?(?<classname>[a-zA-Z0-9_]+)$/.freeze
        private_constant :NAME_REGEX

        private :new # rubocop:disable Style/AccessModifierDeclarations

        def inherited(subclass)
          OpenTelemetry.instrumentation_registry.register(subclass)
        end

        # Optionally set the name of this instrumentation adapter. If not
        # explicitly set, the name will default to the namespace of the class,
        # or the class name if it does not have a namespace. If there is not
        # a namespace, or a class name, it will default to 'unknown'.
        #
        # @param [String] adapter_name The full name of the adapter package
        def adapter_name(adapter_name = nil)
          if adapter_name
            @adapter_name = adapter_name
          else
            @adapter_name ||= infer_name || 'unknown'
          end
        end

        # Optionally set the version of this adapter. If not explicitly set,
        # the version will default to the VERSION constant under namespace of
        # the class, or the VERSION constant under the class name if it does not
        # have a namespace. If a VERSION constant cannot be found, it defaults
        # to '0.0.0'.
        #
        # @param [String] adapter_version The version of the adapter package
        def adapter_version(adapter_version = nil)
          if adapter_version
            @adapter_version = adapter_version
          else
            @adapter_version ||= infer_version || '0.0.0'
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

        def infer_name
          @inferred_name ||= if (md = name.match(NAME_REGEX)) # rubocop:disable Naming/MemoizedInstanceVariableName
                               md['namespace'] || md['classname']
                             end
        end

        def infer_version
          return unless (inferred_name = infer_name)

          mod = inferred_name.split('::').map(&:to_sym).inject(Object) do |object, const|
            object.const_get(const)
          end
          mod.const_get(:VERSION)
        rescue NameError
          nil
        end
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

      # Install adapter with the given config. The present? and compatible?
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
      # be true when the adapter defines an install block, is not disabled
      # by environment or config, and the target library present and compatible.
      #
      # @param [Hash] config The config for this adapter
      def installable?(config = {})
        @install_blk && enabled?(config) && present? && compatible?
      end

      # Calls the present block of the Adapter subclasses, if no block is provided
      # it's assumed the adapter is not present
      def present?
        return false unless @present_blk

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
