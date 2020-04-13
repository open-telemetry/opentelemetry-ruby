# frozen_string_literal: true

# Copyright 2020 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'net/http'

response = Net::HTTP.get('0.0.0.0', '/', '4567')
puts response
