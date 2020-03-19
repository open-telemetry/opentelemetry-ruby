# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'singleton'

module OpenTelemetry
  module SDK
    module Trace
      # NoopSpanProcessor is a singleton implementation of the duck type
      # SpanProcessor that provides synchronous no-op hooks for when a
      # {Span} is started or when a {Span} is ended.
      class NoopSpanProcessor
        include Singleton

        # Called when a {Span} is started, if the {Span#recording?}
        # returns true.
        #
        # This method is called synchronously on the execution thread, should
        # not throw or block the execution thread.
        #
        # @param [Span] span the {Span} that just started.
        def on_start(span); end

        # Called when a {Span} is ended, if the {Span#recording?}
        # returns true.
        #
        # This method is called synchronously on the execution thread, should
        # not throw or block the execution thread.
        #
        # @param [Span] span the {Span} that just ended.
        def on_finish(span); end

        # Export all ended spans to the configured `Exporter` that have not yet
        # been exported.
        #
        # This method should only be called in cases where it is absolutely
        # necessary, such as when using some FaaS providers that may suspend
        # the process after an invocation, but before the `Processor` exports
        # the completed spans.
        def force_flush; end

        # Called when {TracerProvider#shutdown} is called.
        def shutdown; end
      end
    end
  end
end
