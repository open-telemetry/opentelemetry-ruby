# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Instrumentation
    module PG
      module Constants
        # A list of SQL commands, from: https://www.postgresql.org/docs/current/sql-commands.html
        # Commands are truncated to their first word, and all duplicates
        # are removed, This favors brevity and low-cardinality over descriptiveness.
        SQL_COMMANDS = %w[
          ABORT
          ALTER
          ANALYZE
          BEGIN
          CALL
          CHECKPOINT
          CLOSE
          CLUSTER
          COMMENT
          COMMIT
          COPY
          CREATE
          DEALLOCATE
          DECLARE
          DELETE
          DISCARD
          DO
          DROP
          END
          EXECUTE
          EXPLAIN
          FETCH
          GRANT
          IMPORT
          INSERT
          LISTEN
          LOAD
          LOCK
          MOVE
          NOTIFY
          PREPARE
          PREPARE
          REASSIGN
          REFRESH
          REINDEX
          RELEASE
          RESET
          REVOKE
          ROLLBACK
          SAVEPOINT
          SECURITY
          SELECT
          SELECT
          SET
          SHOW
          START
          TRUNCATE
          UNLISTEN
          UPDATE
          VACUUM
          VALUES
        ].freeze

        # From: https://github.com/newrelic/newrelic-ruby-agent/blob/9787095d4b5b2d8fcaf2fdbd964ed07c731a8b6b/lib/new_relic/agent/database/obfuscation_helpers.rb#L9-L34
        COMPONENTS_REGEX_MAP = {
          single_quotes: /'(?:[^']|'')*?(?:\\'.*|'(?!'))/,
          dollar_quotes: /(\$(?!\d)[^$]*?\$).*?(?:\1|$)/,
          uuids: /\{?(?:[0-9a-fA-F]\-*){32}\}?/,
          numeric_literals: /-?\b(?:[0-9]+\.)?[0-9]+([eE][+-]?[0-9]+)?\b/,
          boolean_literals: /\b(?:true|false|null)\b/i,
          comments: /(?:#|--).*?(?=\r|\n|$)/i,
          multi_line_comments: %r{\/\*(?:[^\/]|\/[^*])*?(?:\*\/|\/\*.*)}
        }.freeze

        POSTGRES_COMPONENTS = %i[
          single_quotes
          dollar_quotes
          uuids
          numeric_literals
          boolean_literals
          comments
          multi_line_comments
        ].freeze

        UNMATCHED_PAIRS_REGEX = %r{'|\/\*|\*\/|\$(?!\?)}.freeze

        # These are all alike in that they will have a SQL statement as the first parameter.
        # That statement may possibly be parameterized, but we can still use it - the
        # obfuscation code will just transform $1 -> $? in that case (which is fine enough).
        EXEC_ISH_METHODS = %i[
          exec
          query
          sync_exec
          async_exec
          exec_params
          async_exec_params
          sync_exec_params
        ].freeze

        # The following methods all take a statement name as the first
        # parameter, and a SQL statement as the second - and possibly
        # further parameters after that. We can trace them all alike.
        PREPARE_ISH_METHODS = %i[
          prepare
          async_prepare
          sync_prepare
        ].freeze

        # The following methods take a prepared statement name as their first
        # parameter - everything after that is either potentially quite sensitive
        # (an array of bind params) or not useful to us. We trace them all alike.
        EXEC_PREPARED_ISH_METHODS = %i[
          exec_prepared
          async_exec_prepared
          sync_exec_prepared
        ].freeze
      end
    end
  end
end
