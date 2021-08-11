# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Instrumentation
    module PG
      # The Instrumentation class contains logic to detect and install the Pg instrumentation
      class Instrumentation < OpenTelemetry::Instrumentation::Base
        MINIMUM_VERSION = Gem::Version.new('1.1.0')

        install do |config|
          if config[:enable_sql_obfuscation]
            config[:db_statement] = :obfuscate
            OpenTelemetry.logger.warn(
              'Instrumentation pg configuration option enable_sql_obfuscation has been deprecated,' \
              'use db_statement option instead'
            )
          end

          unless config[:enable_statement_attribute]
            config[:db_statement] = :omit
            OpenTelemetry.logger.warn(
              'Instrumentation pg configuration option enable_statement_attribute has been deprecated,' \
              'use db_statement option instead'
            )
          end

          require_dependencies
          patch_client
        end

        present do
          defined?(::PG)
        end

        compatible do
          Gem.loaded_specs['pg'].version > Gem::Version.new(MINIMUM_VERSION)
        end

        option :peer_service, default: nil, validate: :string
        option :enable_sql_obfuscation, default: false, validate: :boolean
        option :enable_statement_attribute, default: true, validate: :boolean
        option :db_statement, default: :include, validate: ->(opt) { %I[omit include obfuscate].include?(opt) }

        private

        def require_dependencies
          require_relative 'patches/connection'
        end

        def patch_client
          ::PG::Connection.prepend(Patches::Connection)
        end
      end
    end
  end
end
