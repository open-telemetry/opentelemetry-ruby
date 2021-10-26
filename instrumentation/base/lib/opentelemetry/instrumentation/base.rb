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
    class Base # rubocop:disable Metrics/ClassLength
      class << self
        NAME_REGEX = /^(?:(?<namespace>[a-zA-Z0-9_:]+):{2})?(?<classname>[a-zA-Z0-9_]+)$/.freeze
        VALIDATORS = {
          array: ->(v) { v.is_a?(Array) },
          boolean: ->(v) { v == true || v == false }, # rubocop:disable Style/MultipleComparison
          callable: ->(v) { v.respond_to?(:call) },
          integer: ->(v) { v.is_a?(Integer) },
          string: ->(v) { v.is_a?(String) }
        }.freeze
        DEFAULT_OPTIONS = {}.freeze

        private_constant :NAME_REGEX, :VALIDATORS, :DEFAULT_OPTIONS

        private :new # rubocop:disable Style/AccessModifierDeclarations

        def inherited(subclass)
          OpenTelemetry::Instrumentation.registry.register(subclass)
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

        # The option method is used to define default configuration options
        # for the instrumentation library. It requires a name, default value,
        # and a validation callable to be provided.
        # @param [String] name The name of the configuration option
        # @param default The default value to be used, or to used if validation fails
        # @param [Callable, Symbol] validate Accepts a callable or a symbol that matches
        # a key in the VALIDATORS hash.  The supported keys are, :array, :boolean,
        # :callable, :integer, :string.
        def option(name, default:, validate:)
          validate_proc = VALIDATORS[validate] || validate
          raise ArgumentError, "validate must be #{VALIDATORS.keys.join(', ')}, or a callable" unless validate_proc.respond_to?(:call)

          @options ||= []

          @options << { name: name, default: default, validate: validate_proc, validator_type: (VALIDATORS[validate] ? validate : :callable) }
        end

        def instance
          @instance ||= new(instrumentation_name, instrumentation_version, install_blk,
                            present_blk, compatible_blk, options)
        end

        private

        attr_reader :install_blk, :present_blk, :compatible_blk, :options

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

        # default options is used to generate and return a Hash of instrumentation specific default options
        def default_options
          const_defined?(:DEFAULT_OPTIONS) ? const_get(:DEFAULT_OPTIONS) : DEFAULT_OPTIONS
        end

        # initialize_default_options is a convienence method that iterates over all available default_options and sets the configuration
        # options using the option() method.
        #
        # @param [Callable] initialize_default_options An optional default options block for this instrumentation
        # @yieldparam [Hash] default_options The default options for the instrumentation will be yielded to the
        #   initialize_default_options block, which allows an instrumentation author an extensible hook to customize
        #   their defaults dynamically. For example,They may want to check a custom environment variable.
        #   The initialize_default_options block must return a valid default options hash in the format of the DEFAULT_OPTIONS constant.
        def initialize_default_options(&initialize_default_options)
          resolved_options = if initialize_default_options
                               instance_exec(default_options, &initialize_default_options)
                             else
                               default_options
                             end

          raise ArgumentError, 'The initialize_default_options block must return a default options Hash' unless resolved_options.is_a?(::Hash)

          resolved_options.keys.each do |option_name|
            # set option with resolved values (key, env_var || default, validate)
            option(option_name, default: resolved_options[option_name][:default], validate: resolved_options[option_name][:validate])
          end
        end
      end

      attr_reader :name, :version, :config, :installed, :tracer

      alias installed? installed

      def initialize(name, version, install_blk, present_blk,
                     compatible_blk, options)
        @name = name
        @version = version
        @install_blk = install_blk
        @present_blk = present_blk
        @compatible_blk = compatible_blk
        @config = {}
        @installed = false
        @options = options
        @tracer = OpenTelemetry::Trace::Tracer.new
      end

      # Install instrumentation with the given config. The present? and compatible?
      # will be run first, and install will return false if either fail. Will
      # return true if install was completed successfully.
      #
      # @param [Hash] config The config for this instrumentation
      def install(config = {})
        return true if installed?
        return false unless installable?(config)

        @config = config_options(config)
        instance_exec(@config, &@install_blk)
        @tracer = OpenTelemetry.tracer_provider.tracer(name, version)
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

      # The config_options method is responsible for validating that the user supplied
      # config hash is valid.
      # Unknown configuration keys are not included in the final config hash.
      # Invalid configuration values are logged, and replaced by the default.
      #
      # @param [Hash] user_config The user supplied configuration hash
      def config_options(user_config) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
        @options ||= {}
        user_config ||= {}
        user_config = resolve_config_with_env_vars(user_config, @options)
        validated_config = @options.each_with_object({}) do |option, h|
          option_name = option[:name]
          config_value = user_config[option_name]

          value = if config_value.nil?
                    option[:default]
                  elsif option[:validate].call(config_value)
                    config_value
                  else
                    OpenTelemetry.logger.warn(
                      "Instrumentation #{name} configuration option #{option_name} value=#{config_value} " \
                      "failed validation, falling back to default value=#{option[:default]}"
                    )
                    option[:default]
                  end

          h[option_name] = value
        rescue StandardError => e
          OpenTelemetry.handle_error(exception: e, message: "Instrumentation #{name} unexpected configuration error")
          h[option_name] = option[:default]
        end

        dropped_config_keys = user_config.keys - validated_config.keys
        OpenTelemetry.logger.warn("Instrumentation #{name} ignored the following unknown configuration options #{dropped_config_keys}") unless dropped_config_keys.empty?

        validated_config
      end

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

      def resolve_config_with_env_vars(config, options)
        # check for normalized `OTEL_RUBY_INSTRUMENTATION_<NORMALIZED_INSTRUMENTATION_NAME>_OPTS` env var
        instrumentation_name = name
        options_env_var_value = get_options_from_env_var(instrumentation_name)

        env_var_options = options.each_with_object({}) do |option, h|
          option_name = option[:name]

          # extract the raw option value from the environment variable string
          env_var_value = get_option_from_env_var_value(option_name, options_env_var_value)

          # attempt to coerce the environment variable to the type accepted by the validator
          if env_var_value.nil?
            h
          elsif (coerced_value = coerce_env_var(env_var_value, option[:validator_type]))
            h[option_name] = coerced_value
          else
            OpenTelemetry.logger.warn("Environment Variable Option for #{option_name} ignored, certain callable type options can not be configured via environment variable")
            h
          end
        rescue StandardError => e
          OpenTelemetry.handle_error(exception: e, message: "Instrumentation #{name} unexpected configuration error")
          h
        end

        config.merge(env_var_options)
      end

      def get_options_from_env_var(instrumentation_name)
        var_name = instrumentation_name.dup.tap do |n|
          n.upcase!
          n.gsub!('::', '_')
          n.gsub!('OPENTELEMETRY_', 'OTEL_RUBY_')
          n << '_OPTS'
        end

        ENV[var_name]
      end

      def get_option_from_env_var_value(option_name, options_string)
        return if options_string.nil?

        values_map = options_string.split(';').each_with_object({}) do |value_entry, h|
          option_key, option_value = value_entry.split('=')
          h[option_key.to_sym] = option_value.strip
          h
        end

        values_map[option_name]
      rescue StandardError => e
        OpenTelemetry.logger.debug "Error extracting #{name} option #{option_name} from environment variable value #{options_string}: #{e.message}"
        nil
      end

      def coerce_env_var(raw_env_var_value, validation_type)
        case validation_type
        when :array
          env_var_to_array(raw_env_var_value)
        when :boolean
          env_var_to_boolean(raw_env_var_value)
        when :integer
          env_var_to_integer(raw_env_var_value)
        when :string
          env_var_to_string(raw_env_var_value)
        when :callable
          # callable can represent two states. One, a validation that passes the option into a custom proc
          # and second is that the option is itself a custom proc. We want to try supporting the first case via env var,
          # while also preventing garbage values to be passed on the chance someone is attempting the second case.
          # The tradeoff is that we have to guess what the input into a custom proc would be, in practice every custom proc
          # used at the moment is an enumerable, so we can try to coerce the option input to a symbol
          # long term it might make sense to clean this up.
          env_var_to_symbol(raw_env_var_value)
        end
      end

      def env_var_to_boolean(env_var)
        env_var.to_s.strip.downcase == 'true'
      end

      # Returns a integer from an envrionment variable configuration option string
      def env_var_to_integer(env_var)
        env_var.to_i
      end

      # Returns an array from an envrionment variable configuration option string
      def env_var_to_array(env_var)
        env_var ? env_var.split(',').map(&:strip) : default
      end

      # Returns a normalized string from an envrionment variable configuration option string
      def env_var_to_string(env_var)
        env_var.to_s.strip
      end

      # Returns a normalized string from an envrionment variable configuration option string
      def env_var_to_symbol(env_var)
        env_var.to_sym
      end
    end
  end
end
