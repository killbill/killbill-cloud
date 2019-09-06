# frozen_string_literal: true

require 'spec_helper'
require 'kpm/system_helpers/system_proxy'
require 'kpm/system_helpers/cpu_information'

describe KPM::SystemProxy::CpuInformation do
  subject { described_class.new }
  let(:cpu_info) { subject.send(:build_hash, data) }

  context 'when running on Linux' do
    let(:data) { "processor: 0\nvendor_id: GenuineIntel\ncpu family: 6\nmodel: 78\nmodel name: Intel(R) Core(TM) i5-6287U CPU @ 3.10GHz\nstepping: 3\ncpu MHz: 3096.000\ncache size: 4096 KB\nphysical id: 0\nsiblings: 2\ncore id: 0\ncpu cores: 2\napicid: 0\ninitial apicid: 0\nfpu: yes\nfpu_exception: yes\ncpuid level: 22\nwp: yes\nflags: fpu vme de pse tsc msr pae mce cx8 apic sep mtrr pge mca cmov pat pse36 clflush mmx fxsr sse sse2 ht syscall nx rdtscp lm constant_tsc rep_good nopl xtopology nonstop_tsc pni pclmulqdq ssse3 cx16 pcid sse4_1 sse4_2 movbe popcnt aes xsave avx rdrand hypervisor lahf_lm abm 3dnowprefetch fsgsbase avx2 invpcid rdseed clflushopt\nbugs:\nbogomips: 6192.00\nclflush size: 64\ncache_alignment: 64\naddress sizes: 39 bits physical, 48 bits virtual\npower management:\n\nprocessor: 1\nvendor_id: GenuineIntel\ncpu family: 6\nmodel: 78\nmodel name: Intel(R) Core(TM) i5-6287U CPU @ 3.10GHz\nstepping: 3\ncpu MHz: 3096.000\ncache size: 4096 KB\nphysical id: 0\nsiblings: 2\ncore id: 1\ncpu cores: 2\napicid: 1\ninitial apicid: 1\nfpu: yes\nfpu_exception: yes\ncpuid level: 22\nwp: yes\nflags: fpu vme de pse tsc msr pae mce cx8 apic sep mtrr pge mca cmov pat pse36 clflush mmx fxsr sse sse2 ht syscall nx rdtscp lm constant_tsc rep_good nopl xtopology nonstop_tsc pni pclmulqdq ssse3 cx16 pcid sse4_1 sse4_2 movbe popcnt aes xsave avx rdrand hypervisor lahf_lm abm 3dnowprefetch fsgsbase avx2 invpcid rdseed clflushopt\nbugs:\nbogomips: 6192.00\nclflush size: 64\ncache_alignment: 64\naddress sizes: 39 bits physical, 48 bits virtual\npower management:\n\n" }

    it {
      expect(subject.labels).to eq([{ label: :cpu_detail },
                                    { label: :value }])
    }

    it {
      expect(cpu_info).to eq('processor' => { cpu_detail: 'processor', value: '1' },
                             'vendor_id' => { cpu_detail: 'vendor_id', value: 'GenuineIntel' },
                             'cpu family' => { cpu_detail: 'cpu family', value: '6' },
                             'model' => { cpu_detail: 'model', value: '78' },
                             'model name' =>
                                 { cpu_detail: 'model name',
                                   value: 'Intel(R) Core(TM) i5-6287U CPU @ 3.10GHz' },
                             'stepping' => { cpu_detail: 'stepping', value: '3' },
                             'cpu MHz' => { cpu_detail: 'cpu MHz', value: '3096.000' },
                             'cache size' => { cpu_detail: 'cache size', value: '4096 KB' },
                             'physical id' => { cpu_detail: 'physical id', value: '0' },
                             'siblings' => { cpu_detail: 'siblings', value: '2' },
                             'core id' => { cpu_detail: 'core id', value: '1' },
                             'cpu cores' => { cpu_detail: 'cpu cores', value: '2' },
                             'apicid' => { cpu_detail: 'apicid', value: '1' },
                             'initial apicid' => { cpu_detail: 'initial apicid', value: '1' },
                             'fpu' => { cpu_detail: 'fpu', value: 'yes' },
                             'fpu_exception' => { cpu_detail: 'fpu_exception', value: 'yes' },
                             'cpuid level' => { cpu_detail: 'cpuid level', value: '22' },
                             'wp' => { cpu_detail: 'wp', value: 'yes' },
                             'bugs' => { cpu_detail: 'bugs', value: '' },
                             'bogomips' => { cpu_detail: 'bogomips', value: '6192.00' },
                             'clflush size' => { cpu_detail: 'clflush size', value: '64' },
                             'cache_alignment' => { cpu_detail: 'cache_alignment', value: '64' },
                             'address sizes' =>
                                 { cpu_detail: 'address sizes', value: '39 bits physical, 48 bits virtual' },
                             'power management' => { cpu_detail: 'power management', value: '' })
    }
  end

  context 'when running on MacOS' do
    let(:data) { "      Processor Name: Intel Core i5\n      Processor Speed: 3.1 GHz\n      Number of Processors: 1\n      Total Number of Cores: 2\n      L2 Cache (per Core): 256 KB\n      L3 Cache: 4 MB\n" }

    it {
      expect(subject.labels).to eq([{ label: :cpu_detail },
                                    { label: :value }])
    }

    it {
      expect(cpu_info).to eq('Processor Name' => { cpu_detail: 'Processor Name', value: 'Intel Core i5' },
                             'Processor Speed' => { cpu_detail: 'Processor Speed', value: '3.1 GHz' },
                             'Number of Processors' => { cpu_detail: 'Number of Processors', value: '1' },
                             'Total Number of Cores' => { cpu_detail: 'Total Number of Cores', value: '2' },
                             'L2 Cache (per Core)' => { cpu_detail: 'L2 Cache (per Core)', value: '256 KB' },
                             'L3 Cache' => { cpu_detail: 'L3 Cache', value: '4 MB' })
    }
  end
end
