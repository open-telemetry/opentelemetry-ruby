# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Trace
    # SpanData is an immutable object that is used to report out-of-band completed spans.
    #
    # TODO: consider whether to copy collections to a known internal form and expose only enumerations.
    class SpanData
      attr_reader :name, :kind, :start_timestamp, :end_timestamp, :context, :parent_span_id, :resource, :attributes, :timed_events, :links, :status

      def initialize(
        name:,
        kind:,
        start_timestamp:,
        end_timestamp:,
        context:,
        parent_span_id:,
        resource:,
        attributes:,
        timed_events:,
        links:,
        status:
      )
        @name = frozen(name)
        @kind = kind || SpanKind::INTERNAL
        @start_timestamp = start_timestamp
        @end_timestamp = end_timestamp
        @context = context
        @parent_span_id = parent_span_id
        @resource = frozen(resource)
        @attributes = frozen(attributes)
        @timed_events = frozen(timed_events)
        @links = frozen(links)
        @status = frozen(status)
      end

      private

      # TODO: don't clone if already frozen, deep-freeze
      def frozen(obj)
        obj.clone.freeze
      end
    end
  end
end
