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
        MAX_MAJOR_VERSION = 6

        install do |_config|
          require_dependencies
          patch
        end

        present do
          defined?(::ActiveRecord)
        end

        compatible do
          # We know that releases after MAX_MAJOR_VERSION are unstable so we
          # check the major version number of the gem installed to make sure we
          # do not install on a pre-release or full release of the latest
          # if it exceeds the MAX_MAJOR_VERSION version.
          gem_version >= MINIMUM_VERSION && gem_version.segments[0] <= MAX_MAJOR_VERSION
        end

        private

        def insert_class_methods_supported?
          gem_version >= Gem::Version.new('6.0.0')
        end

        def gem_version
          Gem.loaded_specs['activerecord'].version
        end

        def patch
          # The original approach taken here was to patch each individual module of interest.
          # However the patches are applied too late in some applications and as a result the
          # Active Record models will not have the instrumentation patches applied.
          # Prepending the ActiveRecord::Base class is more consistent in applying
          # the patches regardless of initialization order.
          #
          # Modules to prepend to ActiveRecord::Base are still grouped by the source
          # module that they are defined in.
          # Example: Patches::PersistenceClassMethods refers to https://github.com/rails/rails/blob/v6.1.0/activerecord/lib/active_record/persistence.rb#L10
          ::ActiveRecord::Base.prepend(Patches::Querying)
          ::ActiveRecord::Base.prepend(Patches::Persistence)
          ::ActiveRecord::Base.prepend(Patches::PersistenceClassMethods)
          ::ActiveRecord::Base.prepend(Patches::PersistenceInsertClassMethods) if insert_class_methods_supported?
          ::ActiveRecord::Base.prepend(Patches::TransactionsClassMethods)
          ::ActiveRecord::Base.prepend(Patches::Validations)

          ::ActiveRecord::Relation.prepend(Patches::RelationPersistence)
        end

        def require_dependencies
          require_relative 'patches/querying'
          require_relative 'patches/persistence'
          require_relative 'patches/persistence_class_methods'
          require_relative 'patches/persistence_insert_class_methods' if insert_class_methods_supported?
          require_relative 'patches/transactions_class_methods'
          require_relative 'patches/validations'
          require_relative 'patches/relation_persistence'
        end
      end
    end
  end
end
