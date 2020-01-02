# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Instrumentation
    # The Adapter class holds all metadata and configuration for an
    # instrumentation adapter. All instrumentation adapter packages should
    # include a subclass of +Instrumentation::Adapter+ that will register
    # it with +OpenTelemetry::Instrumentation+ and make it available for
    # installation and configuration.
    class Adapter
      class << self
        private :new # rubocop:disable Style/AccessModifierDeclarations

        def inherited(subclass)
          OpenTelemetry::Instrumentation.registry.register(subclass)
        end

        def adapter_name(name) # rubocop:disable Style/TrivialAccessors
          @adapter_name = name
        end

        def adapter_version(version) # rubocop:disable Style/TrivialAccessors
          @adapter_version = version
        end

        def instance
          @instance ||= new(@adapter_name, @adapter_version)
        end
      end

      attr_reader :adapter_name, :adapter_version, :config

      def initialize(adapter_name, adapter_version)
        @adapter_name = adapter_name
        @adapter_version = adapter_version
      end

      # def install
      #   if present? && compatible? && enabled?
      #     #install...
      #   end
      # end
    end
  end
end
