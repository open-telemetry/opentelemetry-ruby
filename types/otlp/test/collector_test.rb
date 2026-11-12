# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe Opentelemetry::Proto do
  Opentelemetry::Proto.constants.each do |collect|
    next if collect != :Collector

    Opentelemetry::Proto.const_get(collect).constants.each do |signal_type|
      describe signal_type.to_s do
        Opentelemetry::Proto.const_get(collect).const_get(signal_type).constants.each do |version|
          describe version.to_s do
            Opentelemetry::Proto.const_get(collect).const_get(signal_type).const_get(version).constants.each do |const|
              it "loads #{const}" do
                value = Opentelemetry::Proto.const_get(collect).const_get(signal_type).const_get(version).const_get(const)
                assert(
                  value.is_a?(Class) || value.is_a?(Module),
                  "Expected #{const} to be a Class or Module, got #{value.class}"
                )
                assert(
                  value.respond_to?(:descriptor) || value.respond_to?(:lookup),
                  "Expected #{const} to be a protobuf message or enum"
                )
              end
            end
          end
        end
      end
    end
  end
end
