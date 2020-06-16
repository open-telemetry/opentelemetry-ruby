# frozen_string_literal: true

# Copyright 2020 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'opentelemetry/sdk'
require 'opentelemetry/resource/detectors/version'
require 'opentelemetry/resource/detectors/google_cloud_platform'
require 'opentelemetry/resource/detectors/auto_detector'

module OpenTelemetry
  module Resource
    # Detectors contains the resource detectors as well as the AutoDetector
    # that can run all the detectors and return an accumlated resource
    module Detectors
    end
  end
end
