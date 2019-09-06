# frozen_string_literal: true

require 'spec_helper'
require 'kpm/system_helpers/system_proxy'
require 'kpm/system_helpers/entropy_available'

describe KPM::SystemProxy::EntropyAvailable do
  subject { described_class.new }
  let(:entropy_info) { subject.send(:build_hash, data) }

  context 'when running on Linux' do
    let(:data) { '182' }

    it {
      expect(subject.labels).to eq([{ label: :entropy },
                                    { label: :value }])
    }

    it {
      expect(entropy_info).to eq({ 'entropy_available' => { entropy: 'available', value: '182' } })
    }
  end

  context 'when running on MacOS' do
    let(:data) { '-' }

    it {
      expect(subject.labels).to eq([{ label: :entropy },
                                    { label: :value }])
    }

    it {
      expect(entropy_info).to eq({ 'entropy_available' => { entropy: 'available', value: '-' } })
    }
  end
end
