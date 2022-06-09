# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'sidekiq/cli'
require 'sidekiq/launcher'

class MockLoader
  attr_reader :launcher

  def initialize
    Sidekiq[:queues] << 'default'

    @launcher = Sidekiq::Launcher.new(Sidekiq)
    @launcher.fire_event(:startup)
  end

  def poller
    launcher.poller
  end

  def manager
    launcher.manager
  end
end
