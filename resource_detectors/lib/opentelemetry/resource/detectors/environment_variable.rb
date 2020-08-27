# frozen_string_literal: true

# Copyright 2020 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Resource
    module Detectors
      # EnvironmentVariables contains detect class method for determining environment variable resource labels
      module EnvironmentVariable
        extend self

        def detect
          resource_labels = {}

          resource_pairs = ENV['OTEL_RESOURCE_ATTRIBUTES']
          return OpenTelemetry::SDK::Resources::Resource.create(resource_labels) unless resource_pairs.is_a?(String)

          resource_pairs.split(',').each do |pair|
            key, value = pair.split('=')
            resource_labels[key] = value
          end

          resource_labels.delete_if { |_key, value| value.nil? || value.empty? }
          OpenTelemetry::SDK::Resources::Resource.create(resource_labels)
        end
      end
    end
  end
end
