# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0
require 'logger'

module OpenTelemetry
  class << self
    attr_accessor :logger
  end

  self.logger = Logger.new(STDOUT)
end
