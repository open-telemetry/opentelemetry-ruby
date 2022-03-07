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

        def detect # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/MethodLength, Metrics/PerceivedComplexity
          gcp_env = Google::Cloud::Env.new
          resource_attributes = {}

          if gcp_env.compute_engine?
            resource_attributes[OpenTelemetry::SemanticConventions::Resource::CLOUD_PROVIDER] = 'gcp'
            resource_attributes[OpenTelemetry::SemanticConventions::Resource::CLOUD_ACCOUNT_ID] = gcp_env.project_id
            resource_attributes[OpenTelemetry::SemanticConventions::Resource::CLOUD_REGION] = gcp_env.instance_attribute('cluster-location')
            resource_attributes[OpenTelemetry::SemanticConventions::Resource::CLOUD_AVAILABILITY_ZONE] = gcp_env.instance_zone

            resource_attributes[OpenTelemetry::SemanticConventions::Resource::HOST_ID] = gcp_env.lookup_metadata('instance', 'id')
            resource_attributes[OpenTelemetry::SemanticConventions::Resource::HOST_NAME] = ENV['HOSTNAME'] ||
                                                                                           gcp_env.lookup_metadata('instance', 'hostname') ||
                                                                                           safe_gethostname
          end

          if gcp_env.kubernetes_engine?
            resource_attributes[OpenTelemetry::SemanticConventions::Resource::K8S_CLUSTER_NAME] = gcp_env.instance_attribute('cluster-name')
            resource_attributes[OpenTelemetry::SemanticConventions::Resource::K8S_NAMESPACE_NAME] = gcp_env.kubernetes_engine_namespace_id
            resource_attributes[OpenTelemetry::SemanticConventions::Resource::K8S_POD_NAME] = ENV['HOSTNAME'] || safe_gethostname
            resource_attributes[OpenTelemetry::SemanticConventions::Resource::K8S_NODE_NAME] = gcp_env.lookup_metadata('instance', 'hostname')

            resource_attributes[OpenTelemetry::SemanticConventions::Resource::CONTAINER_NAME] = ENV['CONTAINER_NAME']
          end

          if gcp_env.knative?
            resource_attributes[OpenTelemetry::SemanticConventions::Resource::CLOUD_PROVIDER] = 'gcp'
            resource_attributes[OpenTelemetry::SemanticConventions::Resource::CLOUD_ACCOUNT_ID] = gcp_env.project_id
            resource_attributes[OpenTelemetry::SemanticConventions::Resource::FAAS_NAME] = gcp_env.knative_service_id
            resource_attributes[OpenTelemetry::SemanticConventions::Resource::FAAS_VERSION] = gcp_env.knative_service_revision
            zone = gcp_env.instance_zone
            resource_attributes[OpenTelemetry::SemanticConventions::Resource::CLOUD_REGION] = get_region zone
            resource_attributes[OpenTelemetry::SemanticConventions::Resource::CLOUD_AVAILABILITY_ZONE] = zone
          end

          resource_attributes.delete_if { |_key, value| value.nil? || value.empty? }
          OpenTelemetry::SDK::Resources::Resource.create(resource_attributes)
        end

        private

        def get_region(zone)
          return if zone.nil? || zone.empty?

          split_arr = zone.split('-', 3)
          split_arr[0].concat('-', split_arr[1])
        end

        def safe_gethostname
          Socket.gethostname
        rescue StandardError
          ''
        end
      end
    end
  end
end
