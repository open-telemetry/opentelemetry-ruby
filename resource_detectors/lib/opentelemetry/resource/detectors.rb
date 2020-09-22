# frozen_string_literal: true

# Copyright 2020 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'opentelemetry/sdk'
require 'opentelemetry/resource/detectors/version'
require 'opentelemetry/resource/detectors/google_cloud_platform'
require 'opentelemetry/resource/detectors/auto_detector'

# OpenTelemetry is an open source observability framework, providing a
# general-purpose API, SDK, and related tools required for the instrumentation
# of cloud-native software, frameworks, and libraries.
#
# The OpenTelemetry module provides global accessors for telemetry objects.
# See the documentation for the `opentelemetry-api` gem for details.
module OpenTelemetry
  module Resource
    # Detectors contains the resource detectors as well as the AutoDetector
    # that can run all the detectors and return an accumlated resource
    module Detectors
    end
  end
end
