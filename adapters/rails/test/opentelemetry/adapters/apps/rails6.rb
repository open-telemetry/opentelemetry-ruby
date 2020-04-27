require 'opentelemetry/adapters/apps/application'

module Rails6
  class Application < RailsTrace::TestApplication
    # By default, ActionView watches the file system for changes template files.
    #
    # Some of the template files in our tests are crated using ActionView::FixtureResolver,
    # which to simulate the presence of those files in memory.
    # These in-memory files have no valid file system path, and cause ActionView
    # refresh mechanism to error out.
    #
    # Enabling `cache_template_loading` forces ActionView to cache templates on first load,
    # and disables any attempt of refresh from the file system.
    config.action_view.cache_template_loading = true
  end
end

Rails6::Application.test_config
