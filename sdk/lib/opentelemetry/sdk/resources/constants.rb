# frozen_string_literal: true

# Copyright 2020 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module SDK
    module Resources
      module Constants
        # Attributes describing a service instance.
        SERVICE_RESOURCE = {
          # Logical name of the service.
          name: 'service.name',

          # A namespace for `service.name`.
          namespace: 'service.namespace',

          # The string ID of the service instance.
          instance_id: 'service.instance.id',

          # The version string of the service API or implementation.
          version: 'service.version'
        }.freeze

        # Attributes describing the telemetry library.
        TELEMETRY_SDK_RESOURCE = {
          # The name of the telemetry library.
          name: 'telemetry.sdk.name',

          # The language of the telemetry library and of the code instrumented with it.
          language: 'telemetry.sdk.language',

          # The version string of the telemetry library
          version: 'telemetry.sdk.version'
        }.freeze

        # Attributes defining a compute unit (e.g. Container, Process, Lambda
        # Function).
        CONTAINER_RESOURCE = {
          # The container name.
          name: 'container.name',

          # The name of the image the container was built on.
          image_name: 'container.image.name',

          # The container image tag.
          image_tag: 'container.image.tag'
        }.freeze

        FAAS_RESOURCE = {
          # The name of the function being executed.
          name: 'faas.name',

          # The unique name of the function being executed.
          id: 'faas.id',

          # The version string of the function being executed.
          version: 'faas.version',

          # The execution environment ID as a string.
          instance: 'faas.instance'
        }.freeze

        # Attributes defining a deployment service (e.g. Kubernetes).
        K8S_RESOURCE = {
          # The name of the cluster that the pod is running in.
          cluster_name: 'k8s.cluster.name',

          # The name of the namespace that the pod is running in.
          namespace_name: 'k8s.namespace.name',

          # The name of the pod.
          pod_name: 'k8s.pod.name',

          # The name of the deployment.
          deployment_name: 'k8s.deployment.name'
        }.freeze

        # Attributes defining a computing instance (e.g. host).
        HOST_RESOURCE = {
          # Hostname of the host. It contains what the hostname command returns on the
          # host machine.
          hostname: 'host.hostname',

          # Unique host id. For Cloud this must be the instance_id assigned by the
          # cloud provider
          id: 'host.id',

          # Name of the host. It may contain what hostname returns on Unix systems,
          # the fully qualified, or a name specified by the user.
          name: 'host.name',

          # Type of host. For Cloud this must be the machine type.
          type: 'host.type',

          # Name of the VM image or OS install the host was instantiated from.
          image_name: 'host.image.name',

          # VM image id. For Cloud, this value is from the provider.
          image_id: 'host.image.id',

          # The version string of the VM image.
          image_version: 'host.image.version'
        }.freeze

        # Attributes defining a running environment (e.g. Cloud, Data Center).
        CLOUD_RESOURCE = {
          # Name of the cloud provider. Example values are aws, azure, gcp.
          provider: 'cloud.provider',

          # The cloud account id used to identify different entities.
          account_id: 'cloud.account.id',

          # A specific geographical location where different entities can run.
          region: 'cloud.region',

          # Zones are a sub set of the region connected through low-latency links.
          zone: 'cloud.zone'
        }.freeze
      end
    end
  end
end
