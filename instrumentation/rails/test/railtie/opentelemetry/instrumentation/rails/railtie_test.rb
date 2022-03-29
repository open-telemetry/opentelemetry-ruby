# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0
require 'test_helper'

class OpenTelemetry::Instrumentation::Rails::RailtieTest < ActiveSupport::TestCase
  include OpenTelemetry::SemanticConventions

  setup do
    OpenTelemetry::Instrumentation.registry.instance_variable_get('@instrumentation').each do |i|
      i.instance_variable_set('@instance', nil)
    end
    OpenTelemetry::SDK::Resources::Resource.instance_variable_set('@default', nil)
    OpenTelemetry.tracer_provider = OpenTelemetry::Internal::ProxyTracerProvider.new
  end

  test 'configures a default instance of the SDK' do
    with_env('OTEL_SERVICE_NAME' => nil) do
      run_initializer
      assert_instance_of(OpenTelemetry::SDK::Trace::TracerProvider, OpenTelemetry.tracer_provider)
      assert_same(Rails.logger, OpenTelemetry.logger.instance_variable_get('@logger'))
    end
  end

  test 'uses standard OTel environment variables for SDK configuration' do
    with_env('OTEL_SERVICE_NAME' => 'test_service_name') do
      run_initializer

      actual_attributes = find_resource_attributes(Resource::SERVICE_NAME)

      expected_attributes = { Resource::SERVICE_NAME => 'test_service_name' }
      assert_equal(expected_attributes, actual_attributes)
    end
  end

  private

  def run_initializer
    Rails.application.initializers.find { |i| i.name == 'opentelemetry.configure' }.run(Rails.application)
  end

  def find_resource_attributes(*keys)
    OpenTelemetry.tracer_provider.resource.attribute_enumerator.to_h.slice(*keys)
  end
end
