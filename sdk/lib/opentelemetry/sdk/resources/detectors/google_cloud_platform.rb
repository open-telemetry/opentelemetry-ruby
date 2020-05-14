# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'google-cloud-env'

module OpenTelemetry
  module SDK
    module Resources
      module Detectors
        # GoogleCloudPlatform contains detect class method for determining gcp environment resource labels
        module GoogleCloudPlatform
          extend self

          def detect
            gcp_env = Google::Cloud::Env.new
            resource_labels = {}

            if gcp_env.compute_engine?
              resource_labels[CLOUD_RESOURCE[:provider]] = 'gcp'
              resource_labels[CLOUD_RESOURCE[:account_id]] = gcp_env.project_id || ''
              resource_labels[CLOUD_RESOURCE[:region]] = gcp_env.instance_attribute('cluster-location') || ''
              resource_labels[CLOUD_RESOURCE[:zone]] = gcp_env.instance_zone || ''

              resource_labels[HOST_RESOURCE[:hostname]] = hostname
              resource_labels[HOST_RESOURCE[:id]] = gcp_env.lookup_metadata('instance', 'id') || ''
              resource_labels[HOST_RESOURCE[:name]] = gcp_env.lookup_metadata('instance', 'hostname') || ''
            end

            if gcp_env.kubernetes_engine?
              resource_labels[K8S_RESOURCE[:cluster_name]] = gcp_env.instance_attribute('cluster-name') || ''
              resource_labels[K8S_RESOURCE[:namespace_name]] = gcp_env.kubernetes_engine_namespace_id || ''
              resource_labels[K8S_RESOURCE[:pod_name]] = hostname

              resource_labels[CONTAINER_RESOURCE[:name]] = ENV['CONTAINER_NAME'] || ''
            end

            Resource.create(resource_labels)
          end

          private

          def hostname
            ENV['HOSTNAME'] || `hostname`&.strip
          rescue StandardError
            ''
          end
        end
      end
    end
  end
end
