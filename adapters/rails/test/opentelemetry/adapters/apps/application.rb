require 'rails/all'
require 'rails/test_help'

module RailsTrace
  class TestApplication < Rails::Application
    # common settings between all Rails versions
    def initialize(*args)
      super(*args)
      file_cache = [:file_store, '/tmp/opentelemetry-rails/cache/']

      config.secret_key_base = 'f624861242e4ccf20eacb6bb48a886da'
      config.cache_store = file_cache
      config.eager_load = false
      config.consider_all_requests_local = true
      config.middleware.delete ActionDispatch::DebugExceptions
    end

    def config.database_configuration
      parsed = super
      raise parsed.to_yaml # Replace this line to add custom connections to the hash from database.yml
    end

    # configure the application: it loads common controllers,
    # initializes the application and runs all migrations;
    # the require order is important
    def test_config
      # Initialize the Rails application
      require 'opentelemetry/adapters/apps/routes'
      initialize!
      require 'opentelemetry/adapters/apps/controllers'
      require 'opentelemetry/adapters/apps/models'
    end
  end
end
