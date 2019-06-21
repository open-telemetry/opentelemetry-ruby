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
  extend self

  def self.tracer
    instance.tracer
  end

  def self.meter
    instance.meter
  end

  def self.distributed_context_manager
    instance.distributed_context_manager
  end

  private

  def self.instance
    # TODO how to configure provider? https://github.com/open-telemetry/opentelemetry-specification/issues/39
    @instance
  end
end

require "opentelemetry/context"
require "opentelemetry/distributed_context"
require "opentelemetry/metrics"
require "opentelemetry/resources"
require "opentelemetry/trace"
require "opentelemetry/version"
