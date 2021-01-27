$TESTING = true

require 'sidekiq/cli'
require 'sidekiq/launcher'

class MockLoader
  include Sidekiq::Util

  attr_reader :launcher

  def initialize
    fire_event(:startup)
    @launcher = Sidekiq::Launcher.new(::Sidekiq.options)
  end

  def poller
    launcher.poller
  end
end
