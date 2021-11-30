# frozen_string_literal: true

# patch `RSpec::Core::DSL::change_global_dsl to reliably prevent
# RSpec overriding minitest's global `::describe` method
require 'rspec/core/dsl'
module RSpec
  module Core
    module DSL
      def self.change_global_dsl(&blk)
        nil
      end
    end
  end
end
