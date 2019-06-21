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
    module Tracer
      def current_span
        return nil
      end

      def with_span(span)
        # TODO set context
        yield span
      ensure
        # TODO pop context
      end

      def create_root_span(name, sampler:, links:, is_recording_events:, kind:)
        fail NotImplementedError, "#{inspect} is an abstract type"
      end

      def create_span(name, with_parent:, with_parent_context: sampler:, links:, is_recording_events:, kind:)
        fail NotImplementedError, "#{inspect} is an abstract type"
      end

      def start_span(name, with_parent:, with_parent_context: sampler:, links:, is_recording_events:, kind:)
        fail NotImplementedError, "#{inspect} is an abstract type"
      end

      def record_span_data(span_data)
        fail NotImplementedError, "#{inspect} is an abstract type"
      end

      def binary_format
        fail NotImplementedError, "#{inspect} is an abstract type"
      end

      def http_text_format
        fail NotImplementedError, "#{inspect} is an abstract type"
      end
    end
  end
end