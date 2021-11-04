# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Instrumentation
    module AwsSdk
      # Instrumentation class that detects and installs the AwsSdk instrumentation
      class Instrumentation < OpenTelemetry::Instrumentation::Base
        MINIMUM_VERSION = Gem::Version.new('2.0')

        install do |_config|
          require_relative './handler'
          require_relative './subscriber'
          require_relative './services'

          add_plugin(Seahorse::Client::Base, *loaded_constants)
        end

        present do
          !defined?(::Seahorse::Client::Base).nil?
        end

        compatible do
          gem_version >= MINIMUM_VERSION
        end

        option :suppress_internal_instrumentation, default: false, validate: :boolean

        private

        def gem_version
          if Gem.loaded_specs['aws-sdk']
            Gem.loaded_specs['aws-sdk'].version
          elsif Gem.loaded_specs['aws-sdk-core']
            Gem.loaded_specs['aws-sdk-core'].version
          end
        end

        def add_plugin(*targets)
          targets.each { |klass| klass.add_plugin(Subscriber) }
        end

        def loaded_constants
          # Cross-check services against loaded AWS constants
          # Module#const_get can return a constant from ancestors when there's a miss.
          # If this conincidentally matches another constant, it will attempt to patch
          # the wrong constant, resulting in patch failure.
          available_services = OpenTelemetry::Instrumentation::AwsSdk.constants & SERVICES.map(&:to_sym)

          available_services.each_with_object([]) do |service, constants|
            next if OpenTelemetry::Instrumentation::AwsSdk.autoload?(service)

            # rubocop:disable RescueModifier
            constants << OpenTelemetry::Instrumentation::AwsSdk.const_get(service, false).const_get(:Client, false) rescue next
            # rubocop:enable RescueModifier
          end
        end

        # TODO: Special handling for S3 URL Presigning. S3::Presigner
        # TODO: SNS / SQS context propagations
      end
    end
  end
end
