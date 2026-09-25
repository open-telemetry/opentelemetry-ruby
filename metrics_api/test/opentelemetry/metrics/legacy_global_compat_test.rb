# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'
require 'open3'

describe OpenTelemetry::Metrics::LegacyGlobalCompat do
  # Each case runs in a subprocess. The shim requires
  # opentelemetry/metrics/global on first use, which cannot be undone, and the
  # legacy SDK it detects is simulated by defining a constant.
  LEGACY_SDK = <<~RUBY
    module OpenTelemetry
      module SDK
        module Metrics
          class MeterProvider; end
        end
      end
    end
  RUBY

  def run_script(body, legacy_sdk: false)
    script = +"require 'opentelemetry-metrics-api'\n"
    script << LEGACY_SDK if legacy_sdk
    script << body

    Open3.capture2e(RbConfig.ruby, '-e', script)
  end

  describe 'without a metrics SDK' do
    it 'leaves the top-level accessor undefined' do
      _, status = run_script(<<~RUBY)
        begin
          OpenTelemetry.meter_provider
          exit 1
        rescue NoMethodError
          exit 0
        end
      RUBY

      assert_predicate(status, :success?, 'expected NoMethodError from OpenTelemetry.meter_provider')
    end

    it 'leaves the top-level writer undefined' do
      _, status = run_script(<<~RUBY)
        begin
          OpenTelemetry.meter_provider = OpenTelemetry::Metrics::MeterProvider.new
          exit 1
        rescue NoMethodError
          exit 0
        end
      RUBY

      assert_predicate(status, :success?, 'expected NoMethodError from OpenTelemetry.meter_provider=')
    end
  end

  describe 'with a legacy metrics SDK' do
    it 'registers a provider through the top-level writer' do
      _, status = run_script(<<~RUBY, legacy_sdk: true)
        provider = OpenTelemetry::Metrics::MeterProvider.new
        OpenTelemetry.meter_provider = provider

        exit(OpenTelemetry::Internal.meter_provider.equal?(provider) ? 0 : 1)
      RUBY

      assert_predicate(status, :success?)
    end

    it 'reads the provider through the top-level accessor' do
      _, status = run_script(<<~RUBY, legacy_sdk: true)
        provider = OpenTelemetry::Metrics::MeterProvider.new
        OpenTelemetry::Internal.meter_provider = provider

        exit(OpenTelemetry.meter_provider.equal?(provider) ? 0 : 1)
      RUBY

      assert_predicate(status, :success?)
    end

    it 'reports respond_to? for the accessors' do
      _, status = run_script(<<~RUBY, legacy_sdk: true)
        exit(OpenTelemetry.respond_to?(:meter_provider) && OpenTelemetry.respond_to?(:meter_provider=) ? 0 : 1)
      RUBY

      assert_predicate(status, :success?)
    end

    it 'warns once, not on every call' do
      output, status = run_script(<<~RUBY, legacy_sdk: true)
        OpenTelemetry.meter_provider = OpenTelemetry::Metrics::MeterProvider.new
        OpenTelemetry.meter_provider
        OpenTelemetry.meter_provider
      RUBY

      assert_predicate(status, :success?)
      _(output.scan('compatibility shim').size).must_equal(1)
    end
  end

  describe 'what it adds to the OpenTelemetry singleton' do
    it 'installs the two hooks and nothing else' do
      _(OpenTelemetry::Metrics::LegacyGlobalCompat.private_instance_methods.sort)
        .must_equal(%i[method_missing respond_to_missing?])
    end
  end

  # Safe to run in process: the shim declines any name outside ACCESSORS
  # regardless of whether opentelemetry/metrics/global has been required.
  describe 'names the shim does not handle' do
    it 'does not report respond_to?' do
      refute_respond_to(OpenTelemetry, :definitely_not_a_method)
    end

    it 'raises NoMethodError' do
      _ { OpenTelemetry.definitely_not_a_method }.must_raise(NoMethodError)
    end
  end

  describe 'unrelated methods' do
    it 'raises without a metrics SDK' do
      _, status = run_script(<<~RUBY)
        begin
          OpenTelemetry.definitely_not_a_method
          exit 1
        rescue NoMethodError
          exit 0
        end
      RUBY

      assert_predicate(status, :success?)
    end

    it 'raises with a legacy metrics SDK' do
      _, status = run_script(<<~RUBY, legacy_sdk: true)
        begin
          OpenTelemetry.definitely_not_a_method
          exit 1
        rescue NoMethodError
          exit 0
        end
      RUBY

      assert_predicate(status, :success?)
    end
  end
end
