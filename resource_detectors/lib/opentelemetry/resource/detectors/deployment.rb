# frozen_string_literal: true

module OpenTelemetry
  module Resource
    module Detectors
      # Deployment contains detect class method for determining deployment resource attributes
      module Deployment
        extend self

        def detect
          resource_attributes = {}
          deployment_environment = rails_env || sinatra_env || rack_env
          resource_attributes[::OpenTelemetry::SemanticConventions::Resource::DEPLOYMENT_ENVIRONMENT] = deployment_environment if deployment_environment
          OpenTelemetry::SDK::Resources::Resource.create(resource_attributes)
        end

        private

        def rails_env
          # rails extract env like this:
          # https://github.com/rails/rails/blob/5647a9c1ced68d20338552d47a3b755e10a271c4/railties/lib/rails.rb#L74
          # ActiveSupport::EnvironmentInquirer.new(ENV["RAILS_ENV"].presence || ENV["RACK_ENV"].presence || "development")
          ::Rails.env.to_str if defined?(::Rails.env)
        end

        def rack_env
          ENV['RACK_ENV']
        end

        def sinatra_env
          # https://github.com/sinatra/sinatra/blob/e69b6b9dee7165d3a583fc8a6af10ceee1ea687d/lib/sinatra/base.rb#L1801
          # cases:
          #
          # 1. if sinatra is "require"d before the detector, then we return the value from the library
          # this case will return the default "development" fallback if not env variable is set which is good.
          #
          # 2. if sinatra is "require"d after the detector, then:
          # 2.1 if user is setting environment via 'APP_ENV' or 'RACK_ENV' then those value will be picked up and reported
          # 2.2 else, the sinatra environment will fallback to "development", but detector will return nil for it.
          # this issue is not covered, as when detector initialize the immutable resource, it has no way
          # of knowing if "sinatra" will be required later or not.
          (::Sinatra::Base.environment.to_s if defined?(::Sinatra::Base.environment)) || ENV['APP_ENV']
        end
      end
    end
  end
end
