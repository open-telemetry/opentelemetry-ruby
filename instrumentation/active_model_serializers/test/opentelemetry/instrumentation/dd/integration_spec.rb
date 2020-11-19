require 'ddtrace/contrib/support/spec_helper'

require 'ddtrace/contrib/active_model_serializers/integration'

RSpec.describe Datadog::Contrib::ActiveModelSerializers::Integration do
  extend ConfigurationHelpers

  let(:integration) { described_class.new(:active_model_serializers) }

  describe '.version' do
    subject(:version) { described_class.version }

    context 'when the "active_model_serializers" gem is loaded' do
      include_context 'loaded gems', active_model_serializers: described_class::MINIMUM_VERSION
      it { is_expected.to be_a_kind_of(Gem::Version) }
    end

    context 'when "active_model_serializers" gem is not loaded' do
      include_context 'loaded gems', active_model_serializers: nil
      it { is_expected.to be nil }
    end
  end

  describe '.loaded?' do
    subject(:loaded?) { described_class.loaded? }

    context 'when neither ActiveModel::Serializer or ActiveSupport::Notifications are defined' do
      before do
        hide_const('ActiveModel::Serializer')
        hide_const('ActiveSupport::Notifications')
      end

      it { is_expected.to be false }
    end

    context 'when only ActiveModel::Serializer is defined' do
      before do
        stub_const('ActiveModel::Serializer', Class.new)
        hide_const('ActiveSupport::Notifications')
      end

      it { is_expected.to be false }
    end

    context 'when only ActiveSupport::Notifications is defined' do
      before do
        hide_const('ActiveModel::Serializer')
        stub_const('ActiveSupport::Notifications', Class.new)
      end

      it { is_expected.to be false }
    end

    context 'when both ActiveModel::Serializer and ActiveSupport::Notifications are defined' do
      before do
        stub_const('ActiveModel::Serializer', Class.new)
        stub_const('ActiveSupport::Notifications', Class.new)
      end

      it { is_expected.to be true }
    end
  end

  describe '.compatible?' do
    subject(:compatible?) { described_class.compatible? }

    context 'when "active_model_serializers" gem is loaded with a version' do
      context 'that is less than the minimum' do
        include_context 'loaded gems', active_model_serializers: decrement_gem_version(described_class::MINIMUM_VERSION)
        it { is_expected.to be false }
      end

      context 'that meets the minimum version' do
        include_context 'loaded gems', active_model_serializers: described_class::MINIMUM_VERSION
        it { is_expected.to be true }
      end
    end

    context 'when gem is not loaded' do
      include_context 'loaded gems', active_model_serializers: nil
      it { is_expected.to be false }
    end
  end

  describe '#default_configuration' do
    subject(:default_configuration) { integration.default_configuration }
    it { is_expected.to be_a_kind_of(Datadog::Contrib::ActiveModelSerializers::Configuration::Settings) }
  end

  describe '#patcher' do
    subject(:patcher) { integration.patcher }
    it { is_expected.to be Datadog::Contrib::ActiveModelSerializers::Patcher }
  end
end
