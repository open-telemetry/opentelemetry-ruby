# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'
require 'opentelemetry/distributed_context/propagation/text_formatter_shared_test_cases'

describe OpenTelemetry::DistributedContext::Propagation::HTTPTextFormat do
  subject { OpenTelemetry::DistributedContext::Propagation::HTTPTextFormat }
  include TextFormatterSharedTestCases
end
