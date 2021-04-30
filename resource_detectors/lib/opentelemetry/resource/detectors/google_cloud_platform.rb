# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'google-cloud-env'

module OpenTelemetry
  module Resource
    module Detectors
      # GoogleCloudPlatform contains detect class method for determining gcp environment resource attributes
      module GoogleCloudPlatform
        extend self

        def detect # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/MethodLength
          gcp_env = Google::Cloud::Env.new
          resource_attributes = {}
          resource_constants = OpenTelemetry::SDK::Resources::Constants

          if gcp_env.compute_engine?
            resource_attributes[resource_constants::CLOUD_RESOURCE[:provider]] = 'gcp'
            resource_attributes[resource_constants::CLOUD_RESOURCE[:account_id]] = gcp_env.project_id
            resource_attributes[resource_constants::CLOUD_RESOURCE[:region]] = gcp_env.instance_attribute('cluster-location')
            resource_attributes[resource_constants::CLOUD_RESOURCE[:availability_zone]] = gcp_env.instance_zone

            resource_attributes[resource_constants::HOST_RESOURCE[:id]] = gcp_env.lookup_metadata('instance', 'id')
            resource_attributes[resource_constants::HOST_RESOURCE[:name]] = ENV['HOSTNAME'] ||
                                                                            gcp_env.lookup_metadata('instance', 'hostname') ||
                                                                            safe_gethostname
          end

          if gcp_env.kubernetes_engine?
            resource_attributes[resource_constants::K8S_RESOURCE[:cluster_name]] = gcp_env.instance_attribute('cluster-name')
            resource_attributes[resource_constants::K8S_RESOURCE[:namespace_name]] = gcp_env.kubernetes_engine_namespace_id
            resource_attributes[resource_constants::K8S_RESOURCE[:pod_name]] = ENV['HOSTNAME'] || safe_gethostname
            resource_attributes[resource_constants::K8S_RESOURCE[:node_name]] = gcp_env.lookup_metadata('instance', 'hostname')

            resource_attributes[resource_constants::CONTAINER_RESOURCE[:name]] = ENV['CONTAINER_NAME']
          end

          resource_attributes.delete_if { |_key, value| value.nil? || value.empty? }
          OpenTelemetry::SDK::Resources::Resource.create(resource_attributes)
        end

        private

        def safe_gethostname
          Socket.gethostname
        rescue StandardError
          ''
        end
      end
    end
  end
end
