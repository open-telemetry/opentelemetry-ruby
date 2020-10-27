# frozen_string_literal: true

# Copyright 2020 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module Rails6
  class Application < Rails::Application
    config.eager_load = false # Ensure we don't see this Rails warning when testing
    config.logger = Logger.new('/dev/null') # Prevent tests from creating log/*.log
    config.hosts << 'example.org'
    config.secret_key_base = 'secret_key_base'
  end
end
