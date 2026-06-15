# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  # OtelConfig module — resource configuration helpers.
  module OtelConfig
    class << self
      # Priority: attributes > attribute_list > detected > base
      def build_resource(resource_cfg)
        base = OpenTelemetry::SDK::Resources::Resource.default

        return base unless resource_cfg

        detected = build_detected_attributes(resource_cfg.detection_development)

        explicit = {}
        Array(resource_cfg.attributes).each do |attr|
          next unless attr.name && !attr.value.nil?

          explicit[attr.name] = coerce_attribute_value(attr.value, attr.type)
        end

        if resource_cfg.attributes_list.is_a?(String)
          resource_cfg.attributes_list.split(',').each do |pair|
            key, value = pair.strip.split('=', 2)
            explicit[key] ||= value if key && value
          end
        end

        OpenTelemetry.logger.warn('OtelConfig: schema_url is supported; ignoring.') if resource_cfg.schema_url

        attrs = detected.merge(explicit)
        custom = OpenTelemetry::SDK::Resources::Resource.create(attrs)
        base.merge(custom)
      end

      private

      # type coercion
      def coerce_attribute_value(value, type)
        case type
        when 'string'       then value.to_s
        when 'bool'         then coerce_bool(value)
        when 'int'          then Integer(value)
        when 'double'       then Float(value)
        when 'string_array' then Array(value).map(&:to_s)
        when 'bool_array'   then Array(value).map { |v| coerce_bool(v) }
        when 'int_array'    then Array(value).map { |v| Integer(v) }
        when 'double_array' then Array(value).map { |v| Float(v) }
        else value # no type field → use the YAML-parsed value as-is
        end
      end

      def coerce_bool(value)
        case value
        when true,  'true',  1 then true
        when false, 'false', 0 then false
        else !!value
        end
      end

      # Extract the attributes from an ExperimentalResourceDetection struct.
      def build_detected_attributes(detection_cfg)
        return {} unless detection_cfg

        included_patterns = Array(detection_cfg.attributes&.included)
        excluded_patterns = Array(detection_cfg.attributes&.excluded)
        detector_names    = detector_names_from(detection_cfg.detectors)

        raw = detector_names.each_with_object({}) do |name, attrs|
          attrs.merge!(run_detector(name).attribute_enumerator.to_h)
        end

        raw.select do |key, _|
          included = included_patterns.empty? || included_patterns.any? { |pat| File.fnmatch(pat, key) }
          excluded = excluded_patterns.any? { |pat| File.fnmatch(pat, key) }
          included && !excluded
        end
      end

      # Flattens an array of ExperimentalResourceDetector structs into the list
      # of detector names whose presence flag is set (e.g. container, host).
      def detector_names_from(detectors)
        Array(detectors).flat_map do |detector|
          next [] unless detector

          names = detector.members.filter_map do |m|
            next if m == :additional_properties

            m.to_s if detector[m]
          end
          names + Array(detector.additional_properties&.keys).map(&:to_s)
        end
      end

      # Returns a Resource for the given detector name.
      def run_detector(name)
        case name
        when 'container'
          detect_resource('OpenTelemetry::Resource::Detector::Container')
        when 'aws'
          # Run all AWS sub-detectors; each returns an empty resource if not on that platform.
          detect_resource('OpenTelemetry::Resource::Detector::AWS', %i[ec2 ecs eks lambda])
        when 'azure'
          detect_resource('OpenTelemetry::Resource::Detector::Azure')
        when 'google_cloud_platform'
          detect_resource('OpenTelemetry::Resource::Detector::GoogleCloudPlatform')
        else
          OpenTelemetry.logger.warn("OtelConfig: unknown resource detector '#{name}'; skipping.")
          OpenTelemetry::SDK::Resources::Resource.create({})
        end
      end

      # Looks up a resource detector class by fully-qualified name and calls detect.
      def detect_resource(class_name, *args)
        Kernel.const_get(class_name).detect(*args)
      rescue NameError
        OpenTelemetry.logger.warn("OtelConfig: resource detector '#{class_name}' is not available — is the gem installed?")
        OpenTelemetry::SDK::Resources::Resource.create({})
      end
    end
  end
end
