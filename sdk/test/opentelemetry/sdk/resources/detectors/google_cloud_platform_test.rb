# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::SDK::Resources::Detectors::GoogleCloudPlatform do
  let(:detector) { OpenTelemetry::SDK::Resources::Detectors::GoogleCloudPlatform }

  describe '.detect' do
    let(:detected_resource) { detector.detect }
    let(:detected_resource_labels) { detected_resource.label_enumerator.to_h }
    let(:expected_resource_labels) { {} }

    it 'returns an empty resource' do
      _(detected_resource).must_be_instance_of(OpenTelemetry::SDK::Resources::Resource)
      _(detected_resource_labels).must_equal(expected_resource_labels)
    end

    describe 'when in a gcp environment' do
      before do
        mock = MiniTest::Mock.new
        mock.expect(:compute_engine?, true)
        mock.expect(:project_id, 'opentelemetry')
        mock.expect(:instance_attribute, 'us-central1', %w(cluster-location))
        mock.expect(:instance_zone, 'us-central1-a')
        mock.expect(:lookup_metadata, 'opentelemetry-test', %w(instance id))
        mock.expect(:lookup_metadata, 'opentelemetry-test', %w(instance hostname))
        mock.expect(:instance_attribute, 'opentelemetry-cluster', %w(cluster-name))
        mock.expect(:kubernetes_engine?, true)
        mock.expect(:kubernetes_engine_namespace_id, 'default')

        with_env('HOSTNAME' => 'opentelemetry-test') do
          Google::Cloud::Env.stub(:new, mock) { detected_resource }
        end
      end

      let(:expected_resource_labels) do
        {
          'cloud.provider' => 'gcp',
          'cloud.account.id' => 'opentelemetry',
          'cloud.region' => 'us-central1',
          'cloud.zone' => 'us-central1-a',
          'host.hostname' => 'opentelemetry-test',
          'host.id' => 'opentelemetry-test',
          'host.name' => 'opentelemetry-test',
          'k8s.cluster.name' => 'opentelemetry-cluster',
          'k8s.namespace.name' => 'default',
          'k8s.pod.name' => 'opentelemetry-test',
          'container.name' => ''
        }
      end

      it 'returns a resource with gcp attributes' do
        _(detected_resource).must_be_instance_of(OpenTelemetry::SDK::Resources::Resource)
        _(detected_resource_labels).must_equal(expected_resource_labels)
      end
    end
  end
end
