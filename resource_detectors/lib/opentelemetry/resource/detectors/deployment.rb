# frozen_string_literal: true

module OpenTelemetry
  module Resource
    module Detectors
      # Deployment contains detect class method for determining deployment resource attributes
      module Deployment
        extend self

        def detect
          resource_attributes = {}
          deployment_environment = get_rails_deployment_environment || get_rack_env
          resource_attributes[::OpenTelemetry::SemanticConventions::Resource::DEPLOYMENT_ENVIRONMENT] = deployment_environment.to_str if deployment_environment
          OpenTelemetry::SDK::Resources::Resource.create(resource_attributes)
        end

        private

        def rails_deployment_environment
          # rails extract env like this:
          # https://github.com/rails/rails/blob/5647a9c1ced68d20338552d47a3b755e10a271c4/railties/lib/rails.rb#L74
          # ActiveSupport::EnvironmentInquirer.new(ENV["RAILS_ENV"].presence || ENV["RACK_ENV"].presence || "development")
          ::Rails.env if defined?(::Rails.env)
        end

        def rack_env
          ENV['RACK_ENV']
        end

        # TODO: add sinatra:
        # https://github.com/sinatra/sinatra/blob/e69b6b9dee7165d3a583fc8a6af10ceee1ea687d/lib/sinatra/base.rb#L1801
      end
    end
  end
end
