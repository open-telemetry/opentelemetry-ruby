# Copyright 2019 OpenTelemetry Authors
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

module OpenTelemetry
  module Trace
    #
    # TODO: consider whether to copy collections to a known internal form and expose only enumerations.
    #
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
        status:,
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
      def frozen(obj); obj.clone.freeze end
    end
  end
end