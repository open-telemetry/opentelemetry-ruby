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
          # Every built instrument, including conflicting duplicates, keyed by downcased name.
          @instrument_descriptors = {}
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
        #
        # Not synchronized on @mutex: create_instrument holds it while waiting on the
        # meter provider's mutex, which the caller of this method already holds.
        # Iterates a snapshot so a concurrent registration cannot mutate the hash mid-iteration.
        def add_metric_reader(metric_reader)
          @instrument_descriptors.values.flatten.each do |descriptor|
            descriptor.instrument.register_with_new_metric_store(metric_reader.metric_store)
          end
        end

        # Validates the given instrument options and creates the instrument of the given kind.
        def create_instrument(kind, name, unit, description, callback, exemplar_filter, exemplar_reservoir, advisory)
          raise InstrumentNameError if invalid_name?(name)
          raise InstrumentUnitError if unit && (!unit.ascii_only? || unit.size > 63)
          raise InstrumentDescriptionError if description && (description.size > 1023 || !utf8mb3_encoding?(description.dup))

          @mutex.synchronize do
            # Read without inserting; the key is only added once an instrument is built.
            descriptors = @instrument_descriptors.fetch(name.downcase, [])

            # Instrument names are case-insensitive, so use the first-seen casing.
            # if first_seen is count, name is Count, then name become count
            first_seen = descriptors.first&.name
            if first_seen && first_seen != name
              OpenTelemetry.logger.warn("case-insensitive duplicate instrument registration occurred:'#{name}' first seen as '#{first_seen}'")
              name = first_seen
            end

            identical = descriptors.find { |descriptor| identical?(descriptor, kind, unit, description) }

            if identical
              OpenTelemetry.logger.warn("repeated observable instrument creation with callbacks for instrument name '#{name}'. Ignoring new callbacks. Use Meter#register_callback to add callbacks.") if callback
              identical.instrument
            else
              # Found the first conflicting instrument with the same name but different attributes (kind, unit, description).
              unless descriptors.empty?
                # TODO: implement the function that can determine if the duplicate registration can be resolved by a view
                # (current View can't rename the instrument name and description)
                OpenTelemetry.logger.warn("duplicate instrument registration occurred for instrument name '#{name}'")
                warn_conflicting_fields(descriptors.first, kind, unit, description)
              end

              # Build and register a new instrument since (still build the instrument even though a conflicting one exists) it has different attributes.
              instrument = build_instrument(kind, name, unit, description, callback, exemplar_filter, exemplar_reservoir)
              # Replace rather than append so arrays already snapshotted by add_metric_reader are never mutated.
              descriptors << InstrumentDescriptor.new(name, kind, unit, description, instrument)
              @instrument_descriptors[name.downcase] = descriptors
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

        # Warns which identifying fields differ from the existing registration.
        # The spec's View-based recipes are omitted because Views cannot rename a stream or override its description.
        def warn_conflicting_fields(existing, kind, unit, description)
          conflicts = []
          conflicts << "kind (#{existing.kind} and #{kind})" if existing.kind != kind
          conflicts << "unit (#{existing.unit.inspect} and #{unit.inspect})" if existing.unit.to_s != unit.to_s
          conflicts << "description (#{existing.description.inspect} and #{description.inspect})" if existing.description.to_s != description.to_s

          OpenTelemetry.logger.warn("conflicting fields: #{conflicts.join(', ')}")
        end
      end
    end
  end
end
