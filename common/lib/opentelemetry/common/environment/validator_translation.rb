# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Common
    module Environment
      # ValidatorTranslation contains common helpers for translation environment variable strings to
      # the appropriate configuration option validator types
      module ValidatorTranslation
        extend self
        # Returns a boolean from an envrionment variable configuration option string

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
          end
        end

        private

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
      end
    end
  end
end
