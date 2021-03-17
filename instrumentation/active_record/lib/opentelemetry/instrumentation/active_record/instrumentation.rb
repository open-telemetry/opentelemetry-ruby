# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Instrumentation
    module ActiveRecord
      # The Instrumentation class contains logic to detect and install the ActiveRecord instrumentation
      class Instrumentation < OpenTelemetry::Instrumentation::Base
        MINIMUM_VERSION = Gem::Version.new('5.2.0')

        install do |_config|
          require_dependencies
          patch
        end

        present do
          defined?(::ActiveRecord)
        end

        compatible do
          gem_version >= MINIMUM_VERSION
        end

        private

        def gem_version
          Gem.loaded_specs['activerecord'].version
        end

        def patch
          ::ActiveRecord::Querying.prepend(Patches::Querying)
          ::ActiveRecord::Persistence.prepend(Patches::Persistence)
          ::ActiveRecord::Persistence::ClassMethods.prepend(Patches::PersistenceClassMethods)
          ::ActiveRecord::Transactions::ClassMethods.prepend(Patches::TransactionsClassMethods)
        end

        def require_dependencies
          require_relative 'patches/querying'
          require_relative 'patches/persistence'
          require_relative 'patches/persistence_class_methods'
          require_relative 'patches/transactions_class_methods'
        end
      end
    end
  end
end
