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
  module Resources
    class Resource
      attr_reader :labels

      def initialize(**kvs)
        # TODO: how defensive should we be here?
        @labels = kvs.to_h { |k, v| [k.to_s.clone.freeze, v.to_s.clone.freeze] }.freeze
      end

      def merge(other)
        new(labels.merge(other.labels))
      end
    end
  end
end