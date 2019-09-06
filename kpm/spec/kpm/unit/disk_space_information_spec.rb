# frozen_string_literal: true

require 'spec_helper'
require 'kpm/system_helpers/system_proxy'
require 'kpm/system_helpers/disk_space_information'

describe KPM::SystemProxy::DiskSpaceInformation do
  subject { described_class.new }
  let(:data_keys) { [] }
  let!(:disk_space_info) { subject.send(:build_hash, data, cols_count, true, data_keys) }

  context 'when running on Linux' do
    let(:cols_count) { 5 }
    let(:data) { "Filesystem     1K-blocks     Used Available Use% Mounted on\nnone            58419028 24656532  30723884  45% /\ntmpfs              65536        0     65536   0% /dev\ntmpfs            5387012        0   5387012   0% /sys/fs/cgroup\n/dev/sda1       58419028 24656532  30723884  45% /etc/hosts\nshm                65536        0     65536   0% /dev/shm\ntmpfs            5387012        0   5387012   0% /sys/firmware\n" }

    it {
      expect(data_keys).to eq(['Filesystem', '1K-blocks', 'Used', 'Available', 'Use%', 'Mounted on'])
    }

    it {
      expect(disk_space_info).to eq('DiskInfo_2' => { Filesystem: 'none', "1K-blocks": '58419028', Used: '24656532', Available: '30723884', "Use%": '45%', Mounted_on: '/' },
                                    'DiskInfo_3' => { Filesystem: 'tmpfs', "1K-blocks": '65536', Used: '0', Available: '65536', "Use%": '0%', Mounted_on: '/dev' },
                                    'DiskInfo_4' => { Filesystem: 'tmpfs', "1K-blocks": '5387012', Used: '0', Available: '5387012', "Use%": '0%', Mounted_on: '/sys/fs/cgroup' },
                                    'DiskInfo_5' => { Filesystem: '/dev/sda1', "1K-blocks": '58419028', Used: '24656532', Available: '30723884', "Use%": '45%', Mounted_on: '/etc/hosts' }, 'DiskInfo_6' => { Filesystem: 'shm', "1K-blocks": '65536', Used: '0', Available: '65536', "Use%": '0%', Mounted_on: '/dev/shm' }, 'DiskInfo_7' => { Filesystem: 'tmpfs', "1K-blocks": '5387012', Used: '0', Available: '5387012', "Use%": '0%', Mounted_on: '/sys/firmware' })
    }
  end

  context 'when running on MacOS' do
    let(:cols_count) { 8 }
    let(:data) { "Filesystem    512-blocks      Used Available Capacity iused               ifree %iused  Mounted on\n/dev/disk1s1   976490576 778131600 173031648    82% 2431747 9223372036852344060    0%   /\ndevfs                690       690         0   100%    1194                   0  100%   /dev\n/dev/disk1s4   976490576  23925200 173031648    13%       5 9223372036854775802    0%   /private/var/vm\nmap -hosts             0         0         0   100%       0                   0  100%   /net\nmap auto_home          0         0         0   100%       0                   0  100%   /home\n/dev/disk1s3   976490576    996584 173031648     1%      34 9223372036854775773    0%   /Volumes/Recovery\n" }

    it {
      expect(data_keys).to eq(['Filesystem', '512-blocks', 'Used', 'Available', 'Capacity', 'iused', 'ifree', '%iused', 'Mounted on'])
    }

    it {
      expect(disk_space_info).to eq('DiskInfo_2' => { Filesystem: '/dev/disk1s1', "512-blocks": '976490576', Used: '778131600', Available: '173031648', Capacity: '82%', iused: '2431747', ifree: '9223372036852344060', "%iused": '0%', Mounted_on: '/' },
                                    'DiskInfo_3' => { Filesystem: 'devfs', "512-blocks": '690', Used: '690', Available: '0', Capacity: '100%', iused: '1194', ifree: '0', "%iused": '100%', Mounted_on: '/dev' },
                                    'DiskInfo_4' => { Filesystem: '/dev/disk1s4', "512-blocks": '976490576', Used: '23925200', Available: '173031648', Capacity: '13%', iused: '5', ifree: '9223372036854775802', "%iused": '0%', Mounted_on: '/private/var/vm' },
                                    'DiskInfo_5' => { Filesystem: 'map', "512-blocks": '-hosts', Used: '0', Available: '0', Capacity: '0', iused: '100%', ifree: '0', "%iused": '0', Mounted_on: '100% /net ' },
                                    'DiskInfo_6' => { Filesystem: 'map', "512-blocks": 'auto_home', Used: '0', Available: '0', Capacity: '0', iused: '100%', ifree: '0', "%iused": '0', Mounted_on: '100% /home ' },
                                    'DiskInfo_7' => { Filesystem: '/dev/disk1s3', "512-blocks": '976490576', Used: '996584', Available: '173031648', Capacity: '1%', iused: '34', ifree: '9223372036854775773', "%iused": '0%', Mounted_on: '/Volumes/Recovery' })
    }
  end
end
