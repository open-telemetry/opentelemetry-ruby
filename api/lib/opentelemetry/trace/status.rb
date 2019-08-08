# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Trace
    # Status represents the status of a finished {Span}. It is composed of a
    # canonical code in conjunction with an optional descriptive message.
    class Status
      # Retrieve the canonical code of this Status.
      #
      # @return [Integer]
      attr_reader :canonical_code

      # Retrieve the description of this Status.
      #
      # @return [String]
      attr_reader :description

      # Initialize a Status.
      #
      # @param [Integer] canonical_code One of the standard GRPC codes: https://github.com/grpc/grpc/blob/master/doc/statuscodes.md
      # @param [String] description
      def initialize(canonical_code, description: '')
        raise ArgumentError unless canonical_code.is_a?(Integer)
        raise ArgumentError unless description.is_a?(String)

        @canonical_code = canonical_code
        @description = description
      end

      # Returns false if this {Status} represents an error, else returns true.
      #
      # @return [Boolean]
      def ok?
        @canonical_code == OK
      end

      # The following represents the canonical set of status codes of a
      # finished {Span}, following the standard GRPC codes:
      # https://github.com/grpc/grpc/blob/master/doc/statuscodes.md

      # The operation completed successfully.
      OK = 0

      # The operation was cancelled (typically by the caller).
      CANCELLED = 1

      # An unknown error.
      UNKNOWN_ERROR = 2

      # Client specified an invalid argument. Note that this differs from
      # {FAILED_PRECONDITION}. {INVALID_ARGUMENT} indicates arguments that are
      # problematic regardless of the state of the system.
      INVALID_ARGUMENT = 3

      # Deadline expired before operation could complete. For operations that
      # change the state of the system, this error may be returned even if the
      # operation has completed successfully.
      DEADLINE_EXCEEDED = 4

      # Some requested entity (e.g., file or directory) was not found.
      NOT_FOUND = 5

      # Some entity that we attempted to create (e.g., file or directory)
      # already exists.
      ALREADY_EXISTS = 6

      # The caller does not have permission to execute the specified operation.
      # {PERMISSION_DENIED} must not be used if the caller cannot be identified
      # (use {UNAUTHENTICATED} instead for those errors).
      PERMISSION_DENIED = 7

      # Some resource has been exhausted, perhaps a per-user quota, or perhaps
      # the entire file system is out of space.
      RESOURCE_EXHAUSTED = 8

      # Operation was rejected because the system is not in a state required
      # for the operation's execution.
      FAILED_PRECONDITION = 9

      # The operation was aborted, typically due to a concurrency issue like
      # sequencer check failures, transaction aborts, etc.
      ABORTED = 10

      # Operation was attempted past the valid range. E.g., seeking or reading
      # past end of file. Unlike {INVALID_ARGUMENT}, this error indicates a
      # problem that may be fixed if the system state changes.
      OUT_OF_RANGE = 11

      # Operation is not implemented or not supported/enabled in this service.
      UNIMPLEMENTED = 12

      # Internal errors. Means some invariants expected by underlying system
      # has been broken.
      INTERNAL_ERROR = 13

      # The service is currently unavailable. This is a most likely a transient
      # condition and may be corrected by retrying with a backoff.
      UNAVAILABLE = 14

      # Unrecoverable data loss or corruption.
      DATA_LOSS = 15

      # The request does not have valid authentication credentials for the
      # operation.
      UNAUTHENTICATED = 16
    end
  end
end
