# frozen_string_literal: true

# Copyright 2020 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  # The ContextUtils module contains convenience methods for inserting and
  # data stored in a Context object.
  module ContextUtils
    extend self

    # Returns the Span from given context, if one exists, nil otherwise.
    #
    # @param [Context] context The context to read the current span from
    # @return [Span, nil]
    def span_from(context)
      context[span_key]
    end

    # Returns the Span from given context, if one exists, nil otherwise.
    #
    # @param [Context] context The context to read the span context from
    # @return [Span, nil]
    def span_context_from(context)
      context[span_context_key]
    end

    # Returns a new context containing the specified Span
    #
    # @param [Span] span Span to be set as the current span in the newly created
    #   context
    # @param [optional Context] parent The parent for the newly created context.
    #   Defaults to Context.current
    # @return [Context]
    def set_span(span, parent: Context.current)
      parent.set_value(span_key, span)
    end

    # Returns a new context containing the specified SpanContext
    #
    # @param [Span] span Span to be set as the current span in the newly created
    #   context
    # @param [optional Context] parent The parent for the newly created context.
    #   Defaults to Context.current
    # @return [Context]
    def set_span_context(span_context, parent: Context.current)
      parent.set_value(span_context_key, span_context)
    end

    private

    def span_key
      Trace::Propagation::ContextKeys.current_span_key
    end

    def span_context_key
      Trace::Propagation::ContextKeys.extracted_span_context_key
    end
  end
end
