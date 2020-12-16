# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require_relative 'events/connection/request'
require_relative 'events/consumer_group/heartbeat'
require_relative 'events/consumer_group/join_group'
require_relative 'events/consumer_group/leave_group'
require_relative 'events/consumer_group/sync_group'
require_relative 'events/produce_operation/send_messages'
require_relative 'events/producer/deliver_messages'

module OpenTelemetry
  module Instrumentation
    module RubyKafka
      module Events
        ALL = [
          Events::Connection::Request,
          Events::ConsumerGroup::Heartbeat,
          Events::ConsumerGroup::JoinGroup,
          Events::ConsumerGroup::LeaveGroup,
          Events::ConsumerGroup::SyncGroup,
          Events::ProduceOperation::SendMessages,
          Events::Producer::DeliverMessages
        ].freeze
      end
    end
  end
end
