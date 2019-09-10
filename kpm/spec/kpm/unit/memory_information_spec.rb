# frozen_string_literal: true

require 'spec_helper'
require 'kpm/system_helpers/system_proxy'
require 'kpm/system_helpers/memory_information'

describe KPM::SystemProxy::MemoryInformation do
  subject { described_class.new }

  context 'when running on Linux' do
    let(:data) { "MemTotal:       10774024 kB\nMemFree:         3788232 kB\nMemAvailable:    9483696 kB\nBuffers:          269216 kB\nCached:          5448624 kB\nSwapCached:            0 kB\nActive:          3562072 kB\nInactive:        2913296 kB\nActive(anon):     827072 kB\nInactive(anon):   124844 kB\nActive(file):    2735000 kB\nInactive(file):  2788452 kB\nUnevictable:           0 kB\nMlocked:               0 kB\nSwapTotal:       3620520 kB\nSwapFree:        3620520 kB\nDirty:                16 kB\nWriteback:             0 kB\nAnonPages:        757472 kB\nMapped:            71548 kB\nShmem:            194392 kB\nSlab:             468096 kB\nSReclaimable:     425428 kB\nSUnreclaim:        42668 kB\nKernelStack:        4816 kB\nPageTables:         3420 kB\nNFS_Unstable:          0 kB\nBounce:                0 kB\nWritebackTmp:          0 kB\nCommitLimit:     9007532 kB\nCommitted_AS:    1711072 kB\nVmallocTotal:   34359738367 kB\nVmallocUsed:           0 kB\nVmallocChunk:          0 kB\nAnonHugePages:    622592 kB\nHugePages_Total:       0\nHugePages_Free:        0\nHugePages_Rsvd:        0\nHugePages_Surp:        0\nHugepagesize:       2048 kB\nDirectMap4k:      166848 kB\nDirectMap2M:    10883072 kB\n" }
    let(:memory_info) { subject.send(:build_hash, data) }

    it {
      expect(subject.labels).to eq([{ label: :memory_detail },
                                    { label: :value }])
    }

    it {
      expect(memory_info).to eq({ 'MemTotal' => { memory_detail: 'MemTotal', value: '10774024 kB' },
                                  'MemFree' => { memory_detail: 'MemFree', value: '3788232 kB' },
                                  'MemAvailable' => { memory_detail: 'MemAvailable', value: '9483696 kB' },
                                  'Buffers' => { memory_detail: 'Buffers', value: '269216 kB' },
                                  'Cached' => { memory_detail: 'Cached', value: '5448624 kB' },
                                  'SwapCached' => { memory_detail: 'SwapCached', value: '0 kB' },
                                  'Active' => { memory_detail: 'Active', value: '3562072 kB' },
                                  'Inactive' => { memory_detail: 'Inactive', value: '2913296 kB' },
                                  'Active(anon)' => { memory_detail: 'Active(anon)', value: '827072 kB' },
                                  'Inactive(anon)' => { memory_detail: 'Inactive(anon)', value: '124844 kB' },
                                  'Active(file)' => { memory_detail: 'Active(file)', value: '2735000 kB' },
                                  'Inactive(file)' => { memory_detail: 'Inactive(file)', value: '2788452 kB' },
                                  'Unevictable' => { memory_detail: 'Unevictable', value: '0 kB' },
                                  'Mlocked' => { memory_detail: 'Mlocked', value: '0 kB' },
                                  'SwapTotal' => { memory_detail: 'SwapTotal', value: '3620520 kB' },
                                  'SwapFree' => { memory_detail: 'SwapFree', value: '3620520 kB' },
                                  'Dirty' => { memory_detail: 'Dirty', value: '16 kB' },
                                  'Writeback' => { memory_detail: 'Writeback', value: '0 kB' },
                                  'AnonPages' => { memory_detail: 'AnonPages', value: '757472 kB' },
                                  'Mapped' => { memory_detail: 'Mapped', value: '71548 kB' },
                                  'Shmem' => { memory_detail: 'Shmem', value: '194392 kB' },
                                  'Slab' => { memory_detail: 'Slab', value: '468096 kB' },
                                  'SReclaimable' => { memory_detail: 'SReclaimable', value: '425428 kB' },
                                  'SUnreclaim' => { memory_detail: 'SUnreclaim', value: '42668 kB' },
                                  'KernelStack' => { memory_detail: 'KernelStack', value: '4816 kB' },
                                  'PageTables' => { memory_detail: 'PageTables', value: '3420 kB' },
                                  'NFS_Unstable' => { memory_detail: 'NFS_Unstable', value: '0 kB' },
                                  'Bounce' => { memory_detail: 'Bounce', value: '0 kB' },
                                  'WritebackTmp' => { memory_detail: 'WritebackTmp', value: '0 kB' },
                                  'CommitLimit' => { memory_detail: 'CommitLimit', value: '9007532 kB' },
                                  'Committed_AS' => { memory_detail: 'Committed_AS', value: '1711072 kB' },
                                  'VmallocTotal' => { memory_detail: 'VmallocTotal', value: '34359738367 kB' },
                                  'VmallocUsed' => { memory_detail: 'VmallocUsed', value: '0 kB' },
                                  'VmallocChunk' => { memory_detail: 'VmallocChunk', value: '0 kB' },
                                  'AnonHugePages' => { memory_detail: 'AnonHugePages', value: '622592 kB' },
                                  'HugePages_Total' => { memory_detail: 'HugePages_Total', value: '0' },
                                  'HugePages_Free' => { memory_detail: 'HugePages_Free', value: '0' },
                                  'HugePages_Rsvd' => { memory_detail: 'HugePages_Rsvd', value: '0' },
                                  'HugePages_Surp' => { memory_detail: 'HugePages_Surp', value: '0' },
                                  'Hugepagesize' => { memory_detail: 'Hugepagesize', value: '2048 kB' },
                                  'DirectMap4k' => { memory_detail: 'DirectMap4k', value: '166848 kB' },
                                  'DirectMap2M' => { memory_detail: 'DirectMap2M', value: '10883072 kB' } })
    }
  end

  context 'when running on MacOS' do
    let(:mem_data) { "Mach Virtual Memory Statistics: (page size of 4096 bytes)\nPages free:                               20436\nPages active:                            279093\nPages inactive:                          276175\nPages speculative:                         2492\nPages throttled:                              0\nPages wired down:                       3328540\nPages purgeable:                          47378\n\"Translation faults\":                1774872371\nPages copy-on-write:                   34313850\nPages zero filled:                   1023660277\nPages reactivated:                    194623586\nPages purged:                          70443047\nFile-backed pages:                       119033\nAnonymous pages:                         438727\nPages stored in compressor:             2771982\nPages occupied by compressor:            287324\nDecompressions:                       252938013\nCompressions:                         328708973\nPageins:                               66884005\nPageouts:                               1122278\nSwapins:                              110783726\nSwapouts:                             113589173\n" }
    let(:mem_total_data) { "      Memory: 16 GB\n" }
    let(:memory_info) { subject.send(:build_hash_mac, mem_data, mem_total_data) }

    it {
      expect(subject.labels).to eq([{ label: :memory_detail },
                                    { label: :value }])
    }

    it {
      expect(memory_info).to eq({ 'Memory' => { memory_detail: 'Memory', value: '16 GB' },
                                  'Mach Virtual Memory Statistics' => { memory_detail: 'Mach Virtual Memory Statistics', value: '0MB' },
                                  'Pages free' => { memory_detail: 'Memory free', value: '79MB' },
                                  'Pages active' => { memory_detail: 'Memory active', value: '1090MB' },
                                  'Pages inactive' => { memory_detail: 'Memory inactive', value: '1078MB' },
                                  'Pages speculative' => { memory_detail: 'Memory speculative', value: '9MB' },
                                  'Pages throttled' => { memory_detail: 'Memory throttled', value: '0MB' },
                                  'Pages wired down' => { memory_detail: 'Memory wired down', value: '13002MB' },
                                  'Pages purgeable' => { memory_detail: 'Memory purgeable', value: '185MB' },
                                  'Translation faults' => { memory_detail: 'Translation faults', value: '6933095MB' },
                                  'Pages copy-on-write' => { memory_detail: 'Memory copy-on-write', value: '134038MB' },
                                  'Pages zero filled' => { memory_detail: 'Memory zero filled', value: '3998672MB' },
                                  'Pages reactivated' => { memory_detail: 'Memory reactivated', value: '760248MB' },
                                  'Pages purged' => { memory_detail: 'Memory purged', value: '275168MB' },
                                  'File-backed pages' => { memory_detail: 'File-backed pages', value: '464MB' },
                                  'Anonymous pages' => { memory_detail: 'Anonymous pages', value: '1713MB' },
                                  'Pages stored in compressor' => { memory_detail: 'Memory stored in compressor', value: '10828MB' },
                                  'Pages occupied by compressor' => { memory_detail: 'Memory occupied by compressor', value: '1122MB' },
                                  'Decompressions' => { memory_detail: 'Decompressions', value: '988039MB' },
                                  'Compressions' => { memory_detail: 'Compressions', value: '1284019MB' },
                                  'Pageins' => { memory_detail: 'Pageins', value: '261265MB' },
                                  'Pageouts' => { memory_detail: 'Pageouts', value: '4383MB' },
                                  'Swapins' => { memory_detail: 'Swapins', value: '432748MB' },
                                  'Swapouts' => { memory_detail: 'Swapouts', value: '443707MB' } })
    }
  end
end
