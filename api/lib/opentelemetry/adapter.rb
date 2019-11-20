# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  # The basic interface for Adapter objects.
  #
  # Adapter class is intended to be subclassed, e.g.,
  #
  #   module Adapters
  #     module SomeLibrary
  #       class Adapter < OpenTelemetry::Adapter
  #       end
  #     end
  #   end
  #
  # then,
  #
  #   Adapters::SomeLibrary.install(name: ..., version: ...)
  class Adapter
    class << self
      attr_reader :config,
                  :meter,
                  :propagation_format,
                  :tracer

      def install(config: nil,
                  meter: nil,
                  propagation_format: nil,
                  tracer: nil)
        @config = config || {}
        @meter = meter
        @propagation_format = propagation_format || default_http_formatter
        @tracer = tracer || default_tracer

        new.install
      end

      private

      def default_http_formatter
        OpenTelemetry.tracer_factory.http_text_format
      end

      def default_tracer
        OpenTelemetry.tracer_factory.tracer(config[:name], config[:version])
      end
    end
  end
end
