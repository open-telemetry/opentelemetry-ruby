# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'opentelemetry'
require 'opentelemetry-instrumentation-base'

module OpenTelemetry
  module Instrumentation
    # Contains the OpenTelemetry instrumentation for the Rack gem
    module Rack
      extend self

      CURRENT_SPAN_KEY = Context.create_key('current-span')

      private_constant :CURRENT_SPAN_KEY

      # Returns the current span from the current or provided context
      #
      # @param [optional Context] context The context to lookup the current
      #   {Span} from. Defaults to Context.current
      def current_span(context = nil)
        context ||= Context.current
        context.value(CURRENT_SPAN_KEY) || OpenTelemetry::Trace::Span::INVALID
      end
    end
  end
end

require_relative './rack/instrumentation'
require_relative './rack/version'
