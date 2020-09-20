# frozen_string_literal: true

# Copyright 2020 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'opentelemetry'

module OpenTelemetry
  module Instrumentation
    # Contains the OpenTelemetry instrumentation for the GraphQL gem
    module GraphQL
    end
  end
end

require_relative './graphql/instrumentation'
require_relative './graphql/version'
