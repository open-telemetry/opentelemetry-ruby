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
    # Design note: MRI optimizes storage of objects with 3 or fewer member variables, inlining the fields into the
    # RVALUE. To take advantage of this, we avoid initializing @trace_options and @tracestate if undefined.
    #
    # TODO: does this optimization buy us anything for the SDK? Are these params ever nil there?
    #
    class SpanContext
      attr_reader :trace_id, :span_id

      def initialize(
        trace_id: generate_trace_id,
        span_id: generate_span_id,
        trace_options: nil,
        tracestate: nil,
      )
        @trace_id = trace_id
        @span_id = span_id
        @trace_options = trace_options if trace_options
        @tracestate = tracestate if tracestate
      end

      def trace_options
        @trace_options || TraceOptions::DEFAULT
      end

      def tracestate
        @tracestate || Tracestate::DEFAULT
      end

      def valid?
        @trace_id.nonzero? && 
    end
  end
end