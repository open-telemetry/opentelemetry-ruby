# frozen_string_literal: true

# Copyright 2020 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require_relative 'middlewares/exception_raising_middleware'
require_relative 'middlewares/redirect_middleware'

::Rails.application.middleware.insert_after(
  ActionDispatch::DebugExceptions,
  ExceptionRaisingMiddleware
)

::Rails.application.middleware.insert_after(
  ActionDispatch::DebugExceptions,
  RedirectMiddleware
)
