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

        def insert_class_methods_supported?
          gem_version >= Gem::Version.new('6.0.0')
        end

        def gem_version
          Gem.loaded_specs['activerecord'].version
        end

        def patch
          # ::ActiveRecord::Querying.prepend(Patches::Querying)
          ::ActiveRecord::Base.prepend(Patches::Querying)

          # ::ActiveRecord::Persistence.prepend(Patches::Persistence)
          ::ActiveRecord::Base.prepend(Patches::Persistence)

          # ::ActiveRecord::Persistence::ClassMethods.prepend(Patches::PersistenceClassMethods)
          ::ActiveRecord::Base.prepend(Patches::PersistenceClassMethods)

          # ::ActiveRecord::Persistence::ClassMethods.prepend(Patches::PersistenceInsertClassMethods) if insert_class_methods_supported?
          ::ActiveRecord::Base.prepend(Patches::PersistenceInsertClassMethods) if insert_class_methods_supported?

          # ::ActiveRecord::Transactions::ClassMethods.prepend(Patches::TransactionsClassMethods)
          ::ActiveRecord::Base.prepend(Patches::TransactionsClassMethods)

          # ::ActiveRecord::Validations.prepend(Patches::Validations)
          ::ActiveRecord::Base.prepend(Patches::Validations)
        end

        def require_dependencies
          require_relative 'patches/querying'
          require_relative 'patches/persistence'
          require_relative 'patches/persistence_class_methods'
          require_relative 'patches/persistence_insert_class_methods' if insert_class_methods_supported?
          require_relative 'patches/transactions_class_methods'
          require_relative 'patches/validations'
        end
      end
    end
  end
end
