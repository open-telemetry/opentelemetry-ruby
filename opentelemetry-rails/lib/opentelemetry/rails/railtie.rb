# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0
module OpenTelemetry
  module Rails
    # Railtie automatically configure the OpentTelemetry SDK
    #
    # This railtie will set defaults for the following environment variables:
    # `OTEL_SERVICE_NAME` - if unset, will default to the Rails application name
    # `OTEL_RESOURCE_ATTRIBUTES` - if unset, will set the deployment environment to the current Rails environment
    #
    # This will also set the `OpenTelemetry.logger` to the Rails logger.
    class Railtie < ::Rails::Railtie
      railtie_name :opentelemetry
      config.opentelemetry = ActiveSupport::OrderedOptions.new
      initializer 'opentelemetry.configure' do |app|
        # See https://api.rubyonrails.org/classes/Rails/Generators/NamedBase.html#method-i-application_name
        ENV['OTEL_SERVICE_NAME'] ||= app.class.name.split('::').first.underscore
        ENV['OTEL_RESOURCE_ATTRIBUTES'] ||= [::OpenTelemetry::SemanticConventions::Resource::DEPLOYMENT_ENVIRONMENT, ::Rails.env].join('=')

        ::OpenTelemetry::SDK.configure do |c|
          c.logger = ::Rails.logger
          c.use_all
        end
      end
    end
  end
end
