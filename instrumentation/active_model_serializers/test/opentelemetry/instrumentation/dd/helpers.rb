module ActiveModelSerializersHelpers
  class << self
    def ams_0_10_or_newer?
      Gem.loaded_specs['active_model_serializers'] \
        && Gem.loaded_specs['active_model_serializers'].version >= Gem::Version.new('0.10')
    end

    def disable_logging
      if ams_0_10_or_newer?
        ActiveModelSerializers.logger.level = Logger::Severity::UNKNOWN
      end
    end
  end
end

RSpec.shared_context 'AMS serializer' do
  let(:serializer_class) do
  end

  if ActiveModelSerializersHelpers.ams_0_10_or_newer?
    before(:each) do
      stub_const('Model', Class.new(ActiveModelSerializers::Model) do
        attr_writer :id
      end)

      stub_const('TestModel', Class.new(Model) do
        attributes :name
      end)

      stub_const('TestModelSerializer', Class.new(ActiveModel::Serializer) do
        attributes :name
      end)
    end
  else
    before(:each) do
      stub_const('Model', Class.new do
        attr_writer :id

        def initialize(hash = {})
          @attributes = hash
        end

        def read_attribute_for_serialization(name)
          if [:id, 'id'].include?(name)
            object_id
          elsif respond_to?(name)
            send name
          else
            @attributes[name]
          end
        end
      end)

      stub_const('TestModel', Class.new(Model))

      stub_const('TestModelSerializer', Class.new(ActiveModel::Serializer) do
        attributes :name
      end)
    end
  end
end
