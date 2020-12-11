# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Instrumentation
    # The Base class holds all metadata and configuration for an
    # instrumentation. All instrumentation packages should
    # include a subclass of +Instrumentation::Base+ that will register
    # it with +OpenTelemetry.instrumentation_registry+ and make it available for
    # discovery and installation by an SDK.
    #
    # A typical subclass of Base will provide an install block, a present
    # block, and possibly a compatible block. Below is an
    # example:
    #
    # module OpenTelemetry
    #   module Instrumentation
    #     module Sinatra
    #       class Instrumentation < OpenTelemetry::Instrumentation::Base
    #         install do |config|
    #           # install instrumentation, either by library hook or applying
    #           # a monkey patch
    #         end
    #
    #         # determine if the target library is present
    #         present do
    #           defined?(::Sinatra)
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
    # The instrumentation name and version will be inferred from the namespace of the
    # class. In this example, they'd be 'OpenTelemetry::Instrumentation::Sinatra' and
    # OpenTelemetry::Instrumentation::Sinatra::VERSION, but can be explicitly set using
    # the +instrumentation_name+ and +instrumetation_version+ methods if necessary.
    #
    # All subclasses of OpenTelemetry::Instrumentation::Base are automatically
    # registered with OpenTelemetry.instrumentation_registry which is used by
    # SDKs for instrumentation discovery and installation.
    #
    # Instrumentation libraries can use the instrumentation subclass to easily gain
    # a reference to its named tracer. For example:
    #
    # OpenTelemetry::Instrumentation::Sinatra.instance.tracer
    #
    # The instrumention class establishes a convention for disabling an instrumentation
    # by environment variable and local configuration. An instrumentation disabled
    # by environment variable will take precedence over local config. The
    # convention for environment variable name is the library name, upcased with
    # '::' replaced by underscores, OPENTELEMETRY shortened to OTEL_{LANG}, and '_ENABLED' appended.
    # For example: OTEL_RUBY_INSTRUMENTATION_SINATRA_ENABLED = false.
    class Base
      class << self
        NAME_REGEX = /^(?:(?<namespace>[a-zA-Z0-9_:]+):{2})?(?<classname>[a-zA-Z0-9_]+)$/.freeze
        private_constant :NAME_REGEX

        private :new # rubocop:disable Style/AccessModifierDeclarations

        def inherited(subclass)
          OpenTelemetry.instrumentation_registry.register(subclass)
        end

        # Optionally set the name of this instrumentation. If not
        # explicitly set, the name will default to the namespace of the class,
        # or the class name if it does not have a namespace. If there is not
        # a namespace, or a class name, it will default to 'unknown'.
        #
        # @param [String] instrumentation_name The full name of the instrumentation package
        def instrumentation_name(instrumentation_name = nil)
          if instrumentation_name
            @instrumentation_name = instrumentation_name
          else
            @instrumentation_name ||= infer_name || 'unknown'
          end
        end

        # Optionally set the version of this instrumentation. If not explicitly set,
        # the version will default to the VERSION constant under namespace of
        # the class, or the VERSION constant under the class name if it does not
        # have a namespace. If a VERSION constant cannot be found, it defaults
        # to '0.0.0'.
        #
        # @param [String] instrumentation_version The version of the instrumentation package
        def instrumentation_version(instrumentation_version = nil)
          if instrumentation_version
            @instrumentation_version = instrumentation_version
          else
            @instrumentation_version ||= infer_version || '0.0.0'
          end
        end

        # The install block for this instrumentation. This will be where you install
        # instrumentation, either by framework hook or applying a monkey patch.
        #
        # @param [Callable] blk The install block for this instrumentation
        # @yieldparam [Hash] config The instrumentation config will be yielded to the
        #   install block
        def install(&blk)
          @install_blk = blk
        end

        # The present block for this instrumentation. This block is used to detect if
        # target library is present on the system. Typically this will involve
        # checking to see if the target gem spec was loaded or if expected
        # constants from the target library are present.
        #
        # @param [Callable] blk The present block for this instrumentation
        def present(&blk)
          @present_blk = blk
        end

        # The compatible block for this instrumentation. This check will be run if the
        # target library is present to determine if it's compatible. It's not
        # required, but a common use case will be to check to target library
        # version for compatibility.
        #
        # @param [Callable] blk The compatibility block for this instrumentation
        def compatible(&blk)
          @compatible_blk = blk
        end

        def instance
          @instance ||= new(instrumentation_name, instrumentation_version, install_blk,
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

      # Install instrumentation with the given config. The present? and compatible?
      # will be run first, and install will return false if either fail. Will
      # return true if install was completed successfully.
      #
      # @param [Hash] config The config for this instrumentation
      def install(config = {})
        return true if installed?
        return false unless installable?(config)

        @config = config unless config.nil?
        instance_exec(@config, &@install_blk)
        @tracer ||= OpenTelemetry.tracer_provider.tracer(name, version)
        @installed = true
      end

      # Whether or not this instrumentation is installable in the current process. Will
      # be true when the instrumentation defines an install block, is not disabled
      # by environment or config, and the target library present and compatible.
      #
      # @param [Hash] config The config for this instrumentation
      def installable?(config = {})
        @install_blk && enabled?(config) && present? && compatible?
      end

      # Calls the present block of the Instrumentation subclasses, if no block is provided
      # it's assumed the instrumentation is not present
      def present?
        return false unless @present_blk

        instance_exec(&@present_blk)
      end

      # Calls the compatible block of the Instrumentation subclasses, if no block is provided
      # it's assumed to be compatible
      def compatible?
        return true unless @compatible_blk

        instance_exec(&@compatible_blk)
      end

      # Whether this instrumentation is enabled. It first checks to see if it's enabled
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

      # Checks to see if this instrumentation is enabled by env var. By convention, the
      # environment variable will be the instrumentation name upper cased, with '::'
      # replaced by underscores, OPENTELEMETRY shortened to OTEL_{LANG} and _ENABLED appended.
      # For example, the, environment variable name for OpenTelemetry::Instrumentation::Sinatra
      # will be OTEL_RUBY_INSTRUMENTATION_SINATRA_ENABLED. A value of 'false' will disable
      # the instrumentation, all other values will enable it.
      def enabled_by_env_var?
        var_name = name.dup.tap do |n|
          n.upcase!
          n.gsub!('::', '_')
          n.gsub!('OPENTELEMETRY_', 'OTEL_RUBY_')
          n << '_ENABLED'
        end
        ENV[var_name] != 'false'
      end
    end
  end
end
