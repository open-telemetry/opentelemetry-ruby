# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module SDK
    # The Metrics module contains the OpenTelemetry metrics reference
    # implementation.
    module Metrics
      # {Meter} is the SDK implementation of {OpenTelemetry::Metrics::Meter}.
      class Meter < OpenTelemetry::Metrics::Meter
        NAME_REGEX = %r{\A[a-zA-Z][-./\w]{0,254}\z}

        # Identifying fields of a created instrument, used to detect duplicate registrations.
        InstrumentDescriptor = Struct.new(:name, :kind, :unit, :description, :instrument)
        private_constant(:InstrumentDescriptor)

        # @api private
        #
        # Returns a new {Meter} instance.
        #
        # @param [String] name Instrumentation scope name
        # @param [String] version Instrumentation scope version
        # @param [optional Hash{String => String, Numeric, Boolean, Array<String, Numeric, Boolean>}] attributes
        #   Instrumentation scope attributes
        #
        # @return [Meter]
        def initialize(name, version, meter_provider, attributes: nil)
          @mutex = Mutex.new
          @instrument_registry = {}
          @instrument_descriptors = Hash.new { |hash, key| hash[key] = [] }
          @instrumentation_scope = InstrumentationScope.new(name, version, attributes || {}.freeze)
          @meter_provider = meter_provider
        end

        # Multiple-instrument callbacks
        # Callbacks registered after the time of instrument creation MAY be associated with multiple instruments.
        # Related spec: https://github.com/open-telemetry/opentelemetry-specification/blob/main/specification/metrics/api.md#multiple-instrument-callbacks
        # Related spec: https://github.com/open-telemetry/opentelemetry-specification/blob/main/specification/metrics/api.md#synchronous-instrument-api
        #
        # @param [Array] instruments A list (or tuple, etc.) of Instruments used in the callback function.
        # @param [Proc] callback A callback function
        #
        # It is RECOMMENDED that the API authors use one of the following forms for the callback function:
        # The list (or tuple, etc.) returned by the callback function contains (Instrument, Measurement) pairs.
        # the Observable Result parameter receives an additional (Instrument, Measurement) pairs
        # Here it chose the second form
        def register_callback(instruments, callback)
          instruments.each do |instrument|
            instrument.register_callback(callback)
          end
        end

        # Removes callback from the given instruments.
        def unregister(instruments, callback)
          instruments.each do |instrument|
            instrument.unregister(callback)
          end
        end

        # @api private
        def add_metric_reader(metric_reader)
          @instrument_registry.each_value do |instrument|
            instrument.register_with_new_metric_store(metric_reader.metric_store)
          end
        end

        # Validates the given instrument options and creates the instrument of the given kind.
        def create_instrument(kind, name, unit, description, callback, exemplar_filter, exemplar_reservoir)
          raise InstrumentNameError if invalid_name?(name)
          raise InstrumentUnitError if unit && (!unit.ascii_only? || unit.size > 63)
          raise InstrumentDescriptionError if description && (description.size > 1023 || !utf8mb3_encoding?(description.dup))

          # Instrument names are case-insensitive, so `super` must key the registry on the first-seen casing.
          name = first_seen_instrument_name(name)

          # The block runs while the base class holds @mutex, so registry lookup,
          # conflict detection and registration are atomic.
          super do
            descriptors = @instrument_descriptors[name.downcase]
            identical = descriptors.find { |descriptor| identical?(descriptor, kind, unit, description) }

            if identical
              identical.instrument
            else
              # Found the first conflicting instrument with the same name but different attributes (kind, unit, description).
              unless descriptors.empty?
                # TODO: implement the function that can determine if the duplicate registration can be resolved by a view
                OpenTelemetry.logger.warn("duplicate instrument registration occurred for instrument name '#{name}'")
                duplicate_registration_resolution(descriptors.first, kind, name, unit)
              end

              # Build and register a new instrument since (still build the instrument even though a conflicting one exists) it has different attributes.
              instrument = build_instrument(kind, name, unit, description, callback, exemplar_filter, exemplar_reservoir)
              descriptors << InstrumentDescriptor.new(name, kind, unit, description, instrument)
              instrument
            end
          end
        end

        # Return true if name is nil/empty or not match NAME_REGEX
        def invalid_name?(name)
          name.to_s.empty? || !NAME_REGEX.match?(name)
        end

        # Returns whether string is valid UTF-8 with no 4-byte (utf8mb4) characters.
        def utf8mb3_encoding?(string)
          string.force_encoding('UTF-8').valid_encoding? &&
            string.each_char { |c| return false if c.bytesize >= 4 }
        end

        private

        # Returns the instrument name that is first seen (or original)
        def first_seen_instrument_name(name)
          first_seen = @mutex.synchronize { @instrument_descriptors[name.downcase].first&.name }

          if first_seen.nil? || first_seen == name
            name
          else
            OpenTelemetry.logger.warn("case-insensitive duplicate instrument registration occurred:'#{name}' first seen as '#{first_seen}'")
            first_seen
          end
        end

        # Returns a new SDK instrument of the given kind.
        def build_instrument(kind, name, unit, description, callback, exemplar_filter, exemplar_reservoir)
          case kind
          when :counter then OpenTelemetry::SDK::Metrics::Instrument::Counter.new(name, unit, description, @instrumentation_scope, @meter_provider, exemplar_filter, exemplar_reservoir)
          when :observable_counter then OpenTelemetry::SDK::Metrics::Instrument::ObservableCounter.new(name, unit, description, callback, @instrumentation_scope, @meter_provider, exemplar_filter, exemplar_reservoir)
          when :gauge then OpenTelemetry::SDK::Metrics::Instrument::Gauge.new(name, unit, description, @instrumentation_scope, @meter_provider, exemplar_filter, exemplar_reservoir)
          when :histogram then OpenTelemetry::SDK::Metrics::Instrument::Histogram.new(name, unit, description, @instrumentation_scope, @meter_provider, exemplar_filter, exemplar_reservoir)
          when :observable_gauge then OpenTelemetry::SDK::Metrics::Instrument::ObservableGauge.new(name, unit, description, callback, @instrumentation_scope, @meter_provider, exemplar_filter, exemplar_reservoir)
          when :up_down_counter then OpenTelemetry::SDK::Metrics::Instrument::UpDownCounter.new(name, unit, description, @instrumentation_scope, @meter_provider, exemplar_filter, exemplar_reservoir)
          when :observable_up_down_counter then OpenTelemetry::SDK::Metrics::Instrument::ObservableUpDownCounter.new(name, unit, description, callback, @instrumentation_scope, @meter_provider, exemplar_filter, exemplar_reservoir)
          end
        end

        # Returns whether an existing registration has the same identifying fields.
        def identical?(descriptor, kind, unit, description)
          descriptor.kind == kind &&
            descriptor.unit.to_s == unit.to_s &&
            descriptor.description.to_s == description.to_s
        end

        # Returns guidance on how to resolve a duplicate instrument registration.
        def duplicate_registration_resolution(existing, kind, name, unit)
          msg = if existing.kind == kind && existing.unit.to_s == unit.to_s
                  'Only the descriptions differ; register both instruments with the same description, ' \
                    "or configure a View for '#{name}' to set a single description."
                elsif existing.kind != kind
                  'The instruments can be distinguished by a View selector; configure a View to rename one of them, ' \
                    "e.g. OpenTelemetry.meter_provider.add_view('#{name}', type: :#{existing.kind})."
                else
                  'The instruments cannot be distinguished by a View selector, so both metrics are exported, ' \
                    'which is a semantic error in the OpenTelemetry data model.'
                end
          OpenTelemetry.logger.warn(msg)
        end
      end
    end
  end
end
