# frozen_string_literal: true

# Copyright 2020 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'opentelemetry'

module OpenTelemetry
  module Instrumentation
    # Contains the OpenTelemetry instrumentation for the Sinatra gem
    module Sinatra
    end
  end
end

require_relative './sinatra/instrumentation'
require_relative './sinatra/version'
