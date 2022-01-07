# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require_relative '../../test_helper'

require 'active_support/all'
require 'active_model_serializers'

# require Instrumentation so .install method is found:
require_relative '../../../lib/opentelemetry/instrumentation/all'

describe OpenTelemetry::Instrumentation::All do
  describe 'ActiveModelSerializers instrumentation' do
    it 'does not conflict with ActiveSupport instrumentation' do
      # Expected behavior is that the exception is not raised.
      OpenTelemetry::Instrumentation::ActiveSupport::Instrumentation.instance.install
      OpenTelemetry::Instrumentation::ActiveModelSerializers::Instrumentation.instance.install
    end
  end
end
