# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'opentelemetry'
require 'opentelemetry-metrics-api'

# Dice provides the core dice-rolling logic instrumented with OpenTelemetry.
# This file depends only on the OpenTelemetry API — all SDK initialization
# is done in otel.rb and loaded by app.rb.
# NOTE: The constants below are evaluated at class-load time and call into the
# OTel SDK immediately. The SDK *must* be fully initialized before this file is
# required. In app.rb, `require_relative 'otel'` is intentionally placed before
# `require_relative 'dice'` to satisfy this dependency. Reordering those requires
# will raise a NoMethodError on OpenTelemetry.tracer_provider / .meter_provider.
class Dice
  TRACER  = OpenTelemetry.tracer_provider.tracer('dice_roller', '0.1.0')
  METER   = OpenTelemetry.meter_provider.meter('dice_roller', version: '0.1.0')

  ROLL_COUNTER   = METER.create_counter(
    'dice.rolls',
    unit: '{roll}',
    description: 'The number of times the dice has been rolled'
  )
  ROLL_HISTOGRAM = METER.create_histogram(
    'dice.roll.value',
    unit: '{roll}',
    description: 'Distribution of dice roll outcomes (1–6)'
  )
  ROLLS_GAUGE    = METER.create_gauge(
    'dice.rolls.requested',
    unit: '{roll}',
    description: 'The last requested number of rolls'
  )

  # Rolls a single die and returns a value between 1 and 6.
  #
  # @return [Integer] a random integer in the range [1, 6]
  def roll
    TRACER.in_span('roll') do |span|
      result = rand(1..6)
      span.set_attribute('dice.value', result)
      ROLL_HISTOGRAM.record(result)
      result
    end
  end

  # Rolls the die +n+ times and returns the results.
  #
  # @param rolls [Integer] number of times to roll (must be a positive integer)
  # @return [Array<Integer>] array of roll results when rolls > 1
  # @return [Integer] single roll result when rolls == 1
  # @raise [ArgumentError] if +rolls+ is not a positive integer
  def roll_dice(rolls)
    TRACER.in_span('roll_dice') do |span|
      raise ArgumentError, 'rolls must be a positive integer' unless rolls.is_a?(Integer) && rolls.positive?

      span.set_attribute('dice.rolls', rolls)
      span.set_attribute('code.function', 'roll_dice')
      span.set_attribute('code.namespace', 'Dice')

      ROLL_COUNTER.add(rolls)
      ROLLS_GAUGE.record(rolls)

      result = if rolls == 1
                 roll
               else
                 Array.new(rolls) { roll }
               end

      result
    rescue ArgumentError => e
      span.record_exception(e)
      span.status = OpenTelemetry::Trace::Status.error(e.message)
      raise
    end
  end
end
