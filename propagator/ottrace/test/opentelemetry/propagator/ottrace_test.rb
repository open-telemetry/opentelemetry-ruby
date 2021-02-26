# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::Propagator::OTTraceTest do
  it 'has a version number' do
    refute_nil ::OpenTelemetry::Propagator::OTTrace::VERSION
  end
end
