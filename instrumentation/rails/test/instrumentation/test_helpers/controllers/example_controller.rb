# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

class ExampleController < ActionController::Base
  include ::Rails.application.routes.url_helpers

  def ok
    render plain: 'actually ok'
  end

  def internal_server_error
    raise :internal_server_error
  end
end
