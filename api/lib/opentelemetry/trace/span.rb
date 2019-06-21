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
    class Span
      attr_reader :context

      def initialize(span_context: nil)
        @context = span_context || SpanContext.new
      end

      def recording_events?
        false
      end

      # TODO: API suggests set_attribute(key:, value:), but this feels more idiomatic?
      def []=(key, value)
        check_not_nil(key, "key")
        check_not_nil(value, "value")
      end

      def add_event(name, **attrs)
        check_not_nil(name, "name")
      end

      def add_link(span_context_or_link, **attrs)
        check_not_nil(span_context_or_link, "span_context_or_link")
        check_empty(attrs, "attrs") unless span_context_or_link.instance_of?(SpanContext)
      end

      def status=(status)
        check_not_nil(status, "status")
      end

      def name=(new_name)
        check_not_nil(new_name, "new_name")
      end

      def end; end
    end
  end
end