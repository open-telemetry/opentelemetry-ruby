# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module SDK
    module Trace
      # NoopSpanProcessor is a singleton implementation of the duck type
      # SpanProcessor that provides synchronous no-op hooks for when a
      # {Span} is started or when a {Span} is ended.
      class NoopSpanProcessor
        include Singleton

        # Called when a {Span} is started, if the {Span#recording_events?}
        # returns true.
        #
        # This method is called synchronously on the execution thread, should
        # not throw or block the execution thread.
        #
        # @param [Span] span the {Span} that just started.
        def on_start(span); end

        # Called when a {Span} is ended, if the {Span#recording_events?}
        # returns true.
        #
        # This method is called synchronously on the execution thread, should
        # not throw or block the execution thread.
        #
        # @param [Span] span the {Span} that just ended.
        def on_finish(span); end

        # Called when {Tracer#shutdown} is called.
        def shutdown; end
      end
    end
  end
end
