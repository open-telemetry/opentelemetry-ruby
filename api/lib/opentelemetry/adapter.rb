# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'opentelemetry'

module OpenTelemetry
  # The basic interface for Adapter objects.
  #
  # Adapter class is intended to be subclassed, e.g.,
  #
  #   module Adapters
  #     module Faraday
  #       class Adapter < OpenTelemetry::Adapter
  #       end
  #     end
  #   end
  #
  # then,
  #
  #   Adapters::Faraday.install(name: ..., version: ...)
  class Adapter
    class << self
      attr_reader :config,
                  :http_formatter,
                  :tracer

      def install(config = {})
        @config = config
        @http_formatter = config[:http_formatter] || default_http_formatter
        @tracer = config[:tracer] || default_tracer
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
