# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Instrumentation
    module ActionView
      SUBSCRIPTIONS = %w[
        render_template.action_view
        render_partial.action_view
        render_collection.action_view
      ].freeze

      # This Railtie sets up subscriptions to relevant ActionView notifications
      class Railtie < ::Rails::Railtie
        config.after_initialize do
          ::OpenTelemetry::Instrumentation::ActiveSupport::Instrumentation.instance.install({})

          SUBSCRIPTIONS.each do |subscription_name|
            config = ActionView::Instrumentation.instance.config
            ::OpenTelemetry::Instrumentation::ActiveSupport.subscribe(ActionView::Instrumentation.instance.tracer, subscription_name, config[:notification_payload_transform], config[:disallowed_notification_payload_keys])
          end
        end
      end
    end
  end
end
