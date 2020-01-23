# frozen_string_literal: true

require 'spec_helper'
require 'kpm/system_helpers/system_proxy'
require 'kpm/system_helpers/os_information'

describe KPM::SystemProxy::OsInformation do
  subject { described_class.new }
  let(:os_data) { subject.send(:build_hash, data) }

  context 'when running on Linux' do
    let(:data) { "Description:Ubuntu 16.04.1 LTS \n\n" }

    it {
      expect(subject.labels).to eq([{ label: :os_detail },
                                    { label: :value }])
    }

    it {
      expect(os_data).to eq({ 'Description' => { :os_detail => 'Description', :value => 'Ubuntu 16.04.1 LTS' } })
    }
  end

  context 'when running on MacOS' do
    let(:data) { "ProductName:\tMac OS X\nProductVersion:\t10.14.6\nBuildVersion:\t18G87\n" }

    it {
      expect(subject.labels).to eq([{ label: :os_detail },
                                    { label: :value }])
    }

    it {
      expect(os_data).to eq({ 'ProductName' => { :os_detail => 'ProductName', :value => 'Mac OS X' },
                              'ProductVersion' => { :os_detail => 'ProductVersion', :value => '10.14.6' },
                              'BuildVersion' => { :os_detail => 'BuildVersion', :value => '18G87' } })
    }
  end
end
