# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module SDK
    module Trace
      # No-op implementation of a tracer factory.
      class TracerFactory
        Key = Struct.new(:name, :version)
        private_constant(:Key)

        # Returns a new {TracerFactory} instance.
        #
        # @return [TracerFactory]
        def initialize
          @mutex = Mutex.new
          @registry = {}
        end

        # Returns a {Tracer} instance.
        #
        # @param [optional String] name Instrumentation package name
        # @param [optional String] version Instrumentation package version
        #
        # @return [Tracer]
        def tracer(name = nil, version = nil)
          name ||= ''
          version ||= ''
          @mutex.synchronize { @registry[Key.new(name, version)] ||= Tracer.new(name, version) }
        end
      end
    end
  end
end
