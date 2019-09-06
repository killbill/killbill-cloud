# frozen_string_literal: true

require 'spec_helper'

describe 'Formatter' do
  describe KPM::Formatter::DefaultFormatter do
    subject { described_class.new(label, input) }

    context 'when arguments are nil' do
      let(:label) { nil }
      let(:input) { nil }

      it { expect(subject.size).to eq(0) }
      it { expect(subject.to_s).to eq('') }
      it { expect(subject.label).to eq('') }
    end

    context 'when arguments are non-nil' do
      let(:label) { 'my_label' }
      let(:input) { 'my_value' }

      it { expect(subject.size).to eq(8) }
      it { expect(subject.to_s).to eq('my_value') }
      it { expect(subject.label).to eq('MY LABEL') }
    end
  end

  describe KPM::Formatter::VersionFormatter do
    subject { described_class.new(label, versions) }

    context 'when arguments are nil/empty' do
      let(:label) { nil }
      let(:versions) { [] }

      it { expect(subject.size).to eq(0) }
      it { expect(subject.to_s).to eq('') }
      it { expect(subject.label).to eq(' sha1=[], def=(*), del=(x)') }
    end

    context 'when arguments are non-nil' do
      let(:label) { 'my_label' }
      let(:versions) do
        [{ version: '1.0', is_default: false, is_disabled: false, sha1: nil },
         { version: '2.0', is_default: true, is_disabled: true, sha1: '123456789' }]
      end

      it { expect(subject.size).to eq(29) }
      it { expect(subject.to_s).to eq('1.0[???], 2.0[123456..](*)(x)') }
      it { expect(subject.label).to eq('MY LABEL sha1=[], def=(*), del=(x)') }
    end
  end

  describe KPM::Formatter do
    subject { described_class.new }

    context 'when running inspect' do
      let(:data) do
        { 'killbill-kpm' => { plugin_name: 'killbill-kpm', plugin_path: '/var/tmp/bundles/plugins/ruby/killbill-kpm', type: 'ruby', versions: [{ version: '1.3.0', is_default: true, is_disabled: false, sha1: 'b350016c539abc48e51c97605ac1f08b441843d3' }], plugin_key: 'kpm', group_id: 'org.kill-bill.billing.plugin.ruby', artifact_id: 'kpm-plugin', packaging: 'tar.gz', classifier: nil },
          'hello-world-plugin' => { plugin_name: 'hello-world-plugin', plugin_path: '/var/tmp/bundles/plugins/java/hello-world-plugin', type: 'java', versions: [{ version: '1.0.1-SNAPSHOT', is_default: true, is_disabled: false, sha1: nil }], plugin_key: 'dev:hello', group_id: nil, artifact_id: nil, packaging: nil, classifier: nil },
          'analytics-plugin' => { plugin_name: 'analytics-plugin', plugin_path: '/var/tmp/bundles/plugins/java/analytics-plugin', type: 'java', versions: [{ version: '7.0.3-SNAPSHOT', is_default: true, is_disabled: false, sha1: nil }], plugin_key: 'analytics', group_id: nil, artifact_id: nil, packaging: nil, classifier: nil } }
      end
      let(:labels) do
        [{ label: :plugin_name },
         { label: :plugin_key },
         { label: :type },
         { label: :group_id },
         { label: :artifact_id },
         { label: :packaging },
         { label: :versions, formatter: KPM::Formatter::VersionFormatter.name }]
      end
      let!(:labels_format_argument) { subject.send(:compute_labels, data, labels) }

      it {
        expect(labels_format_argument).to eq(['PLUGIN NAME',
                                              'PLUGIN KEY',
                                              'TYPE',
                                              'GROUP ID',
                                              'ARTIFACT ID',
                                              'PACKAGING',
                                              'VERSIONS sha1=[], def=(*), del=(x)'])
      }

      it {
        expect(labels).to eq([{ label: :plugin_name, size: 18 },
                              { label: :plugin_key, size: 10 },
                              { label: :type, size: 4 },
                              { label: :group_id, size: 33 },
                              { label: :artifact_id, size: 11 },
                              { label: :packaging, size: 9 },
                              { label: :versions, formatter: KPM::Formatter::VersionFormatter.name, size: 34 }])
      }

      it {
        # labels have the size computed here already
        expect(subject.send(:compute_border, labels)).to eq('_____________________________________________________________________________________________________________________________________________')
      }

      it {
        # labels have the size computed here already
        expect(subject.send(:compute_format, labels)).to eq('| %18s | %10s | %4s | %33s | %11s | %9s | %34s |')
      }

      it {
        expect(subject.send(:format_only, data, labels)).to eq("\n_____________________________________________________________________________________________________________________________________________
|        PLUGIN NAME | PLUGIN KEY | TYPE |                          GROUP ID | ARTIFACT ID | PACKAGING | VERSIONS sha1=[], def=(*), del=(x) |
_____________________________________________________________________________________________________________________________________________
|       killbill-kpm |        kpm | ruby | org.kill-bill.billing.plugin.ruby |  kpm-plugin |    tar.gz |                 1.3.0[b35001..](*) |
| hello-world-plugin |  dev:hello | java |                               ??? |         ??? |       ??? |             1.0.1-SNAPSHOT[???](*) |
|   analytics-plugin |  analytics | java |                               ??? |         ??? |       ??? |             7.0.3-SNAPSHOT[???](*) |
_____________________________________________________________________________________________________________________________________________\n\n")
      }
    end

    context 'when formatting CPU information' do
      let(:data) do
        { 'Processor Name' => { cpu_detail: 'Processor Name', value: 'Intel Core i5' },
          'Processor Speed' => { cpu_detail: 'Processor Speed', value: '3.1 GHz' },
          'Number of Processors' => { cpu_detail: 'Number of Processors', value: '1' },
          'Total Number of Cores' => { cpu_detail: 'Total Number of Cores', value: '2' },
          'L2 Cache (per Core)' => { cpu_detail: 'L2 Cache (per Core)', value: '256 KB' },
          'L3 Cache' => { cpu_detail: 'L3 Cache', value: '4 MB' } }
      end
      let(:labels) do
        [{ label: :cpu_detail },
         { label: :value }]
      end
      let!(:labels_format_argument) { subject.send(:compute_labels, data, labels) }

      it {
        expect(labels_format_argument).to eq(['CPU DETAIL',
                                              'VALUE'])
      }

      it {
        expect(labels).to eq([{ label: :cpu_detail, size: 21 },
                              { label: :value, size: 13 }])
      }

      it {
        # labels have the size computed here already
        expect(subject.send(:compute_border, labels)).to eq('_________________________________________')
      }

      it {
        # labels have the size computed here already
        expect(subject.send(:compute_format, labels)).to eq('| %21s | %13s |')
      }

      it {
        expect(subject.send(:format_only, data, labels)).to eq("\n_________________________________________
|            CPU DETAIL |         VALUE |
_________________________________________
|        Processor Name | Intel Core i5 |
|       Processor Speed |       3.1 GHz |
|  Number of Processors |             1 |
| Total Number of Cores |             2 |
|   L2 Cache (per Core) |        256 KB |
|              L3 Cache |          4 MB |
_________________________________________\n\n")
      }
    end
  end
end
