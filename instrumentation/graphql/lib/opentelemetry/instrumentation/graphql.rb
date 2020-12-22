# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'opentelemetry'

module OpenTelemetry
  module Instrumentation
    # Contains the OpenTelemetry instrumentation for the Graphql gem
    module GraphQL
    end
  end
end

require_relative './graphql/instrumentation'
require_relative './graphql/version'
