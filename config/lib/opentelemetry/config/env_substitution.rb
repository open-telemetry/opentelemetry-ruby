# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Config
    # Loads configuration file YAML with environment variable substitution.
    #
    # References of the form +${NAME}+, +${env:NAME}+, and +${NAME:-default}+ are
    # replaced in scalar values, and +$$+ escapes a literal +$+. Mapping keys are
    # left untouched. Types are resolved after substitution, so a plain
    # +${PORT}+ loads as an Integer while a quoted +"${PORT}"+ stays a String.
    module EnvSubstitution
      # Raised when a configuration file contains an invalid substitution reference.
      class Error < StandardError; end

      # A colon followed by "-" starts a default value, not a prefix.
      REFERENCE = /\$\{(?:(?<prefix>[a-zA-Z][a-zA-Z0-9_]*):(?!-))?(?<content>[^}]+)\}/
      ENV_REFERENCE = /\A(?<name>[a-zA-Z_][a-zA-Z0-9_]*)(?::-(?<default>[^\n]*))?\z/
      PERMITTED_CLASSES = %w[Date Time].freeze
      private_constant :REFERENCE, :ENV_REFERENCE, :PERMITTED_CLASSES

      module_function

      # Parses YAML and substitutes environment variables in its scalar values.
      #
      # @param content [String] YAML document
      # @param env [Hash{String => String}] environment variables to substitute
      # @return [Object, nil] the loaded document, or nil when it is empty
      # @raise [Error] when a substitution reference is invalid
      # @raise [Psych::Exception] when the YAML is invalid or uses a disallowed
      #   class or alias
      def load(content, env = ENV)
        document = Psych.parse(content)
        return unless document

        substitute_node(document, env)

        class_loader = Psych::ClassLoader::Restricted.new(PERMITTED_CLASSES, [])
        scanner = Psych::ScalarScanner.new(class_loader)
        Psych::Visitors::NoAliasRuby.new(scanner, class_loader).accept(document)
      end

      # Substitutes environment variable references in a string.
      #
      # @param value [String]
      # @param env [Hash{String => String}] environment variables to substitute
      # @return [String]
      # @raise [Error] when a substitution reference is invalid
      def substitute(value, env = ENV)
        # Split on escapes first so a "$" they produce never starts a reference.
        value.split('$$', -1).map do |segment|
          segment.gsub(REFERENCE) { resolve(Regexp.last_match, env) }
        end.join('$')
      end

      # Substitutes scalar values in a node tree, skipping mapping keys.
      def substitute_node(node, env)
        case node
        when Psych::Nodes::Scalar
          node.value = substitute(node.value, env)
        when Psych::Nodes::Mapping
          node.children.each_slice(2) { |_key, value| substitute_node(value, env) }
        else
          Array(node.children).each { |child| substitute_node(child, env) }
        end
      end

      # Returns the replacement for a matched reference.
      def resolve(match, env)
        reference = ENV_REFERENCE.match(match[:content]) if match[:prefix].nil? || match[:prefix] == 'env'
        raise Error, "invalid substitution reference #{match[0]}" unless reference

        value = env[reference[:name]]
        return value unless value.nil? || value.empty?

        reference[:default].to_s
      end
      private_class_method :substitute_node, :resolve
    end
  end
end
