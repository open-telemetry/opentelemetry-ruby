# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'sidekiq/cli'
require 'sidekiq/launcher'

class MockLoader
  include Sidekiq::Util

  attr_reader :launcher

  def initialize
    fire_event(:startup)
    options = ::Sidekiq.options
    options[:queues] << 'default'
    @launcher = Sidekiq::Launcher.new(options)
  end

  def poller
    launcher.poller
  end

  def manager
    launcher.manager
  end
end
