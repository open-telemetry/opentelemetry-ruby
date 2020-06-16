# frozen_string_literal: true

# Copyright 2020 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'google-cloud-env'

module OpenTelemetry
  module Resource
    module Detectors
      # GoogleCloudPlatform contains detect class method for determining gcp environment resource labels
      module GoogleCloudPlatform
        extend self

        def detect # rubocop:disable Metrics/AbcSize
          gcp_env = Google::Cloud::Env.new
          resource_labels = {}
          resource_constants = OpenTelemetry::SDK::Resources::Constants

          if gcp_env.compute_engine?
            resource_labels[resource_constants::CLOUD_RESOURCE[:provider]] = 'gcp'
            resource_labels[resource_constants::CLOUD_RESOURCE[:account_id]] = gcp_env.project_id
            resource_labels[resource_constants::CLOUD_RESOURCE[:region]] = gcp_env.instance_attribute('cluster-location')
            resource_labels[resource_constants::CLOUD_RESOURCE[:zone]] = gcp_env.instance_zone

            resource_labels[resource_constants::HOST_RESOURCE[:hostname]] = hostname
            resource_labels[resource_constants::HOST_RESOURCE[:id]] = gcp_env.lookup_metadata('instance', 'id')
            resource_labels[resource_constants::HOST_RESOURCE[:name]] = gcp_env.lookup_metadata('instance', 'hostname')
          end

          if gcp_env.kubernetes_engine?
            resource_labels[resource_constants::K8S_RESOURCE[:cluster_name]] = gcp_env.instance_attribute('cluster-name')
            resource_labels[resource_constants::K8S_RESOURCE[:namespace_name]] = gcp_env.kubernetes_engine_namespace_id
            resource_labels[resource_constants::K8S_RESOURCE[:pod_name]] = hostname

            resource_labels[resource_constants::CONTAINER_RESOURCE[:name]] = ENV['CONTAINER_NAME']
          end

          resource_labels.delete_if { |_key, value| value.nil? || value.empty? }
          OpenTelemetry::SDK::Resources::Resource.create(resource_labels)
        end

        private

        def hostname
          ENV['HOSTNAME'] || Socket.gethostname
        rescue StandardError
          ''
        end
      end
    end
  end
end
