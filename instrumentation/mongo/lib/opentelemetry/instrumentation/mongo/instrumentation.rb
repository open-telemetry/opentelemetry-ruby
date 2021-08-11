# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Instrumentation
    module Mongo
      # Instrumentation class that detects and installs the Mongo instrumentation
      class Instrumentation < OpenTelemetry::Instrumentation::Base
        MINIMUM_VERSION = Gem::Version.new('2.5.0')

        install do |_config|
          require_dependencies
          register_subscriber
        end

        present do
          !defined?(::Mongo::Monitoring::Global).nil?
        end

        compatible do
          gem_version >= MINIMUM_VERSION
        end

        option :peer_service, default: nil, validate: :string
        option :db_statement, default: :include, validate: ->(opt) { %I[omit include].include?(opt) }

        private

        def gem_version
          Gem.loaded_specs['mongo']&.version
        end

        def require_dependencies
          require_relative 'subscriber'
        end

        def register_subscriber
          # Subscribe to all COMMAND queries with our subscriber class
          ::Mongo::Monitoring::Global.subscribe(::Mongo::Monitoring::COMMAND, Subscriber.new)
        end
      end
    end
  end
end
