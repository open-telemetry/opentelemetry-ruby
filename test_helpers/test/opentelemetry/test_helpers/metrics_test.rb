# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

require 'opentelemetry/test_helpers/metrics' # not loaded by default

describe OpenTelemetry::TestHelpers::Metrics do
  describe 'dependencies' do
    let(:gemspec) { Gem.loaded_specs.fetch('opentelemetry-test-helpers') }
    let(:dependencies) { gemspec.dependencies.map(&:name) }

    # NOTE: The `metrics` module here is intended to facilitate testing
    # for instrumentation libraries that should function with or without
    # the metrics-api in the bundle. Including it in this test helper
    # should be considered a mistake unless additional provisions are made to preserve
    # this feature.
    it 'does not include the api or sdk gems' do
      _(dependencies).wont_include('opentelemetry-metrics-sdk')
      _(dependencies).wont_include('opentelemetry-metrics-api')
    end
  end
end
