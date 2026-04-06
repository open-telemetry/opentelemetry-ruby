# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

# Dice provides the core dice-rolling logic, independent of any HTTP framework
# or OpenTelemetry instrumentation.
class Dice
  # Rolls a single die and returns a value between 1 and 6.
  #
  # @return [Integer] a random integer in the range [1, 6]
  def roll
    rand(1..6)
  end

  # Rolls the die +n+ times and returns the results.
  #
  # @param rolls [Integer] number of times to roll (must be a positive integer)
  # @return [Array<Integer>] array of roll results when rolls > 1
  # @return [Integer] single roll result when rolls == 1
  # @raise [ArgumentError] if +rolls+ is not a positive integer
  def roll_dice(rolls)
    raise ArgumentError, "rolls must be a positive integer" unless rolls.is_a?(Integer) && rolls.positive?

    if rolls == 1
      roll
    else
      Array.new(rolls) { roll }
    end
  end
end
