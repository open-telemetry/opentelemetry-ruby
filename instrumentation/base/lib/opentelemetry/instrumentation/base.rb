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
    # A typical subclass of Base will provide a library name, an install block, a present block, e.g.:
    #
    # module OpenTelemetry
    #   module Instrumentation
    #     module Sinatra
    #       class Instrumentation < OpenTelemetry::Instrumentation::Base
    #         # Declare instrumented library:
    #         library_name 'sinatra'
    #
    #         install do |config|
    #           # install instrumentation, either by library hook or applying
    #           # a monkey patch
    #         end
    #
    #         # determine if the target library is present
    #         present do
    #           defined?(::Sinatra)
    #         end
    #       end
    #     end
    #   end
    # end
    #
    # In cases where the instrumentation is not able to use `library_name` to check against gem specifications,
    # subclasses may provide a custom code block to check compatibility at start up time, e.g.
    #
    # module OpenTelemetry
    #   module Instrumentation
    #     module CustomLibrary
    #       class Instrumentation < OpenTelemetry::Instrumentation::Base
    #         MIN_VERSION = '3.2.1'
    #         install do |config|
    #           # install instrumentation, either by library hook or applying
    #           # a monkey patch
    #         end
    #
    #         # determine if the target library is present
    #         present do
    #           defined?(::CustomLibrary)
    #         end
    #
    #         # if the target library is present, is it compatible?
    #         compatible do
    #           ::CustomLibrary::VERSION > MIN_VERSION
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

        private_constant :NAME_REGEX, :VALIDATORS

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

        # Optionally set the library name being instrumented.
        #
        # Set this value in lieu writing a custom compatible block.
        # @param [String] library_name must match the gem specification name of the instrumented library
        def library_name(library_name = nil)
          @library_name ||= library_name
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
          validator = VALIDATORS[validate] || validate
          raise ArgumentError, "validate must be #{VALIDATORS.keys.join(', ')}, or a callable" unless validator.respond_to?(:call) || validator.respond_to?(:include?)

          @options ||= []

          validation_type = if VALIDATORS[validate]
                              validate
                            elsif validate.respond_to?(:include?)
                              :enum
                            else
                              :callable
                            end

          @options << { name: name, default: default, validator: validator, validation_type: validation_type }
        end

        def instance
          @instance ||= new(instrumentation_name, instrumentation_version, library_name, install_blk,
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
      end

      attr_reader :name, :version, :config, :installed, :tracer, :library_name, :instrumentation_gem_name

      alias installed? installed

      def initialize(name, version, library_name, install_blk, present_blk,
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
        @library_name = library_name
        @instrumentation_gem_name = @library_name.nil? ? nil : "opentelemetry-instrumentation-#{@library_name}"
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

      # Checks compatability of this instrumentation with its designated library
      #
      # Subclasses are compatible by default unless they specify
      # - a custom compatible block
      # - a `library_name` use to compare gemspecs
      def compatible?
        return true unless @compatible_blk || library_name

        if @compatible_blk
          instance_exec(&@compatible_blk)
        else
          compatible_version?
        end
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

      # EXPERIMENTAL: Checks compatability of `library_name` against the `development_dependency` declared in instrumentations gemspec
      #
      # This method will first search `Gem.loaded_specs` to locate gemspecs that have already been required by RubyGems or Bundler.
      # In the case the gems were not loaded, or do not use RubyGems/Bundler, it will fallback to searching for installed gems via `Gem::Specification.find_by_name`.
      #
      # Instrumentation authors are encouraged to implement a `present` block to ensure the constants are availble to use in monkey patches.
      #
      # See https://github.com/DataDog/dd-trace-rb/pull/1510
      # rubocop:disable Metrics/AbcSize
      def compatible_version?
        instrumentation_spec = Gem.loaded_specs[instrumentation_gem_name] || Gem::Specification.find_by_name(instrumentation_gem_name)
        library_spec = Gem.loaded_specs[library_name] || Gem::Specification.find_by_name(library_name)

        dependency = instrumentation_spec.development_dependencies.find { |spec| spec.name == library_name }
        dependency&.requirement&.satisfied_by?(library_spec&.version) == true
      rescue Gem::MissingSpecError => e
        OpenTelemetry.handle_error(message: 'Instrumentation Compatibility Check Error', exception: e)
        false
      end
      # rubocop:enable Metrics/AbcSize

      # The config_options method is responsible for validating that the user supplied
      # config hash is valid.
      # Unknown configuration keys are not included in the final config hash.
      # Invalid configuration values are logged, and replaced by the default.
      #
      # @param [Hash] user_config The user supplied configuration hash
      def config_options(user_config) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
        @options ||= {}
        user_config ||= {}
        config_overrides = config_overrides_from_env
        validated_config = @options.each_with_object({}) do |option, h|
          option_name = option[:name]
          config_value = user_config[option_name]
          config_override = coerce_env_var(config_overrides[option_name], option[:validation_type]) if config_overrides[option_name]

          value = if config_value.nil? && config_override.nil?
                    option[:default]
                  elsif option[:validator].respond_to?(:include?) && option[:validator].include?(config_override)
                    config_override
                  elsif option[:validator].respond_to?(:include?) && option[:validator].include?(config_value)
                    config_value
                  elsif option[:validator].respond_to?(:call) && option[:validator].call(config_override)
                    config_override
                  elsif option[:validator].respond_to?(:call) && option[:validator].call(config_value)
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

      def config_overrides_from_env
        var_name = name.dup.tap do |n|
          n.upcase!
          n.gsub!('::', '_')
          n.gsub!('OPENTELEMETRY_', 'OTEL_RUBY_')
          n << '_CONFIG_OPTS'
        end

        environment_config_overrides = {}
        env_config_options = ENV[var_name]&.split(';')

        return environment_config_overrides if env_config_options.nil?

        env_config_options.each_with_object(environment_config_overrides) do |env_config_option, eco|
          parts = env_config_option.split('=')
          option_name = parts[0].to_sym
          eco[option_name] = parts[1]
        end

        environment_config_overrides
      end

      def coerce_env_var(env_var, validation_type) # rubocop:disable Metrics/CyclomaticComplexity
        case validation_type
        when :array
          env_var.split(',').map(&:strip)
        when :boolean
          env_var.to_s.strip.downcase == 'true'
        when :integer
          env_var.to_i
        when :string
          env_var.to_s.strip
        when :enum
          env_var.to_s.strip.to_sym
        when :callable
          OpenTelemetry.logger.warn(
            "Instrumentation #{name} options that accept a callable are not " \
            "configurable using environment variables. Ignoring raw value: #{env_var}"
          )
          nil
        end
      end
    end
  end
end
