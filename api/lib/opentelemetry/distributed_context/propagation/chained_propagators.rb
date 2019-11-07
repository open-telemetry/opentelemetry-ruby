# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module DistributedContext
    module Propagation
      # @todo add module documentation
      module ChainedPropagators
        # @todo add class documentation
        class Injector
          def initialize(injector1, injector2)
            @injector1 = injector1
            @injector2 = injector2
          end

          def inject(context, carrier, &setter)
            injector1.inject(context, carrier, setter)
            injector2.inject(context, carrier, setter)
          end
        end

        # @todo add class documentation
        class Extractor
          def initialize(extractor1, extractor2)
            @extractor1 = extractor1
            @extractor2 = extractor2
          end

          def extract(context, carrier, &getter)
            context = extractor1.extract(context, carrier, getter)
            context = extractor2.extract(context, carrier, getter)
            context
          end
        end

        private_constant(:Injector, :Extractor)

        def chain_http_injectors(injector1, injector2)
          Injector.new(injector1, injector2)
        end

        def chain_http_extractors(extractor1, extractor2)
          Extractor.new(extractor1, extractor2)
        end
      end
    end
  end
end
