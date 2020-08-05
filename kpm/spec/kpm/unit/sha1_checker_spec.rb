# frozen_string_literal: true

require 'spec_helper'

describe KPM::Sha1Checker do
  let(:tmp_dir) { Dir.mktmpdir('sha1_checker_spec') }
  let(:sha1_file) { File.join(tmp_dir, 'sha1.yml') }
  let(:sha1_checker) { KPM::Sha1Checker.from_file(sha1_file) }
  let(:sha1_content) do
    {
      'sha1' => { 'org.kill-bill.billing.plugin.ruby:killbill-plugin-match:tar.gz:1.0.0' => 'fce068c3fd5f95646ce0d09852f43ff67f06f0b9',
                  'org.kill-bill.billing.plugin.ruby:killbill-plugin-nomatch:tar.gz:1.0.0' => 'ace068c3fd5f95646ce0d09852f43ff67f06f0b8',
                  'org.kill-bill.billing.plugin.ruby:killbill-plugin-other:tar.gz:1.0.0' => 'bbb068c3fd5f95646ce0d09852f43ff67f06fccc' },
      'nexus' => { 'org.kill-bill.billing.plugin.ruby:killbill-plugin-match:tar.gz:1.0.0' => { :sha1 => 'fce068c3fd5f95646ce0d09852f43ff67f06f0b9',
                                                                                               :version => '1.0.0',
                                                                                               :repository_path => '/org/kill-bill/billing/plugin/ruby/killbill-plugin-match/1.0.0/killbill-plugin-match-1.0.0.tar.gz',
                                                                                               :is_tgz => true },
                   'org.kill-bill.billing.plugin.ruby:killbill-plugin-nomatch:tar.gz:1.0.0' => { :sha1 => 'ace068c3fd5f95646ce0d09852f43ff67f06f0b8',
                                                                                                 :version => '1.0.0',
                                                                                                 :repository_path => '/org/kill-bill/billing/plugin/ruby/killbill-plugin-nomatch/1.0.0/killbill-plugin-nomatch-1.0.0.tar.gz',
                                                                                                 :is_tgz => true },
                   'org.kill-bill.billing.plugin.ruby:killbill-plugin-other:tar.gz:1.0.0' => { :sha1 => 'bbb068c3fd5f95646ce0d09852f43ff67f06fccc',
                                                                                               :version => '1.0.0',
                                                                                               :repository_path => '/org/kill-bill/billing/plugin/ruby/killbill-plugin-other/1.0.0/killbill-plugin-other-1.0.0.tar.gz',
                                                                                               :is_tgz => true } },
      'killbill' => { '0.20.10' => { 'killbill' => '0.20.10', 'killbill-oss-parent' => '0.142.7', 'killbill-api' => '0.52.0', 'killbill-plugin-api' => '0.25.0', 'killbill-commons' => '0.22.3', 'killbill-platform' => '0.38.3' },
                      '0.20.12' => { 'killbill' => '0.20.12', 'killbill-oss-parent' => '0.142.7', 'killbill-api' => '0.52.0', 'killbill-plugin-api' => '0.25.0', 'killbill-commons' => '0.22.3', 'killbill-platform' => '0.38.3' },
                      '0.18.5' => { 'killbill' => '0.18.5', 'killbill-oss-parent' => '0.140.18', 'killbill-api' => '0.50.1', 'killbill-plugin-api' => '0.23.1', 'killbill-commons' => '0.20.5', 'killbill-platform' => '0.36.5' } }
    }
  end

  before do
    File.open(sha1_file.to_s, 'w') { |l| l.puts(sha1_content.to_yaml) }
  end

  it 'should create intermediate directories' do
    Dir.mktmpdir do |dir|
      config = File.join(dir, 'foo', 'bar', 'baz', 'sha1.yml')
      expect(File.exist?(config)).to be_falsey
      KPM::Sha1Checker.from_file(config)
      expect(File.exist?(config)).to be_truthy
    end
  end

  it 'translates LATEST when caching nexus info' do
    sha1_checker.cache_artifact_info('org.kill-bill.billing.plugin.java:analytics-plugin:jar:LATEST', { :sha1 => '050594dd73a54d229ca3efcf69785345b8cd1681',
                                                                                                        :version => '7.0.4',
                                                                                                        :repository_path => '/org/kill-bill/billing/plugin/java/analytics-plugin/7.0.4/analytics-plugin-7.0.4.jar',
                                                                                                        :is_tgz => false })
    expect(sha1_checker.artifact_info('org.kill-bill.billing.plugin.java:analytics-plugin:jar:LATEST')).to be_nil
    expect(sha1_checker.artifact_info('org.kill-bill.billing.plugin.java:analytics-plugin:jar:7.0.4')[:sha1]).to eq('050594dd73a54d229ca3efcf69785345b8cd1681')
  end

  it 'never caches nexus info without version info' do
    sha1_checker.cache_artifact_info('org.kill-bill.billing.plugin.java:analytics-plugin:jar:LATEST', { :sha1 => '050594dd73a54d229ca3efcf69785345b8cd1681',
                                                                                                        :repository_path => '/org/kill-bill/billing/plugin/java/analytics-plugin/7.0.4/analytics-plugin-7.0.4.jar',
                                                                                                        :is_tgz => false })
    expect(sha1_checker.artifact_info('org.kill-bill.billing.plugin.java:analytics-plugin:jar:LATEST')).to be_nil
    expect(sha1_checker.artifact_info('org.kill-bill.billing.plugin.java:analytics-plugin:jar:7.0.4')).to be_nil
  end

  it 'finds matching sha1' do
    existing_sha1 = sha1_checker.sha1('org.kill-bill.billing.plugin.ruby:killbill-plugin-match:tar.gz:1.0.0')
    expect(existing_sha1).to eq('fce068c3fd5f95646ce0d09852f43ff67f06f0b9')

    existing_nexus = sha1_checker.artifact_info('org.kill-bill.billing.plugin.ruby:killbill-plugin-match:tar.gz:1.0.0')
    expect(existing_nexus[:sha1]).to eq(existing_sha1)
  end

  it 'does not find matching sha1' do
    existing_sha1 = sha1_checker.sha1('killbill-plugin-foo:tar.gz:1.0.0')
    expect(existing_sha1).to be_nil

    existing_nexus = sha1_checker.artifact_info('killbill-plugin-foo:tar.gz:1.0.0')
    expect(existing_nexus).to be_nil
  end

  it 'adds an entry and find them all' do
    sha1_checker.add_or_modify_entry!('killbill-plugin-new:tar.gz:1.1.0.0', 'abc068c3fd5f95646ce0d09852f43ff67f06f111')

    existing = sha1_checker.sha1('org.kill-bill.billing.plugin.ruby:killbill-plugin-match:tar.gz:1.0.0')
    expect(existing).to eq('fce068c3fd5f95646ce0d09852f43ff67f06f0b9')

    # Nexus cache untouched
    existing_nexus = sha1_checker.artifact_info('org.kill-bill.billing.plugin.ruby:killbill-plugin-match:tar.gz:1.0.0')
    expect(existing_nexus[:sha1]).to eq(existing)

    existing = sha1_checker.sha1('killbill-plugin-new:tar.gz:1.1.0.0')
    expect(existing).to eq('abc068c3fd5f95646ce0d09852f43ff67f06f111')

    # Nexus cache not updated
    expect(sha1_checker.artifact_info('killbill-plugin-new:tar.gz:1.1.0.0')).to be_nil

    existing = sha1_checker.sha1('org.kill-bill.billing.plugin.ruby:killbill-plugin-other:tar.gz:1.0.0')
    expect(existing).to eq('bbb068c3fd5f95646ce0d09852f43ff67f06fccc')

    # Nexus cache untouched
    existing_nexus = sha1_checker.artifact_info('org.kill-bill.billing.plugin.ruby:killbill-plugin-other:tar.gz:1.0.0')
    expect(existing_nexus[:sha1]).to eq(existing)
  end

  it 'modifies an entry and find them all' do
    existing = sha1_checker.sha1('org.kill-bill.billing.plugin.ruby:killbill-plugin-match:tar.gz:1.0.0')
    expect(existing).to eq('fce068c3fd5f95646ce0d09852f43ff67f06f0b9')

    existing_nexus = sha1_checker.artifact_info('org.kill-bill.billing.plugin.ruby:killbill-plugin-match:tar.gz:1.0.0')
    expect(existing_nexus[:sha1]).to eq(existing)

    sha1_checker.add_or_modify_entry!('org.kill-bill.billing.plugin.ruby:killbill-plugin-match:tar.gz:1.0.0', 'dde068c3fd5f95646ce0d09852f43ff67f06f0aa')

    existing = sha1_checker.sha1('org.kill-bill.billing.plugin.ruby:killbill-plugin-match:tar.gz:1.0.0')
    expect(existing).to eq('dde068c3fd5f95646ce0d09852f43ff67f06f0aa')

    # Nexus cache untouched (modified in another code path)
    existing_nexus = sha1_checker.artifact_info('org.kill-bill.billing.plugin.ruby:killbill-plugin-match:tar.gz:1.0.0')
    expect(existing_nexus[:sha1]).to eq('fce068c3fd5f95646ce0d09852f43ff67f06f0b9')

    existing = sha1_checker.sha1('org.kill-bill.billing.plugin.ruby:killbill-plugin-other:tar.gz:1.0.0')
    expect(existing).to eq('bbb068c3fd5f95646ce0d09852f43ff67f06fccc')

    existing_nexus = sha1_checker.artifact_info('org.kill-bill.billing.plugin.ruby:killbill-plugin-other:tar.gz:1.0.0')
    expect(existing_nexus[:sha1]).to eq(existing)
  end

  context 'when removing an entry' do
    let(:identifier) { 'org.kill-bill.billing.plugin.ruby:killbill-plugin-match:tar.gz:1.0.0' }
    before do
      sha1_checker.remove_entry!(identifier)
    end

    it 'does not find the entry' do
      expect(sha1_checker.sha1(identifier)).to be_nil
      expect(sha1_checker.artifact_info(identifier)).to be_nil
    end

    it 'does not find entry in file system' do
      expect(KPM::Sha1Checker.from_file(sha1_file).sha1(identifier)).to be_nil
    end
  end

  it 'works with empty config' do
    Dir.mktmpdir do |dir|
      empty_config = File.join(dir, 'sha1.yml')
      sha1_checker = KPM::Sha1Checker.from_file(empty_config)
      sha1_checker.add_or_modify_entry!('killbill-plugin-new:tar.gz:1.1.0.0', 'abc068c3fd5f95646ce0d09852f43ff67f06f111')
      existing = sha1_checker.sha1('killbill-plugin-new:tar.gz:1.1.0.0')
      expect(existing).to eq('abc068c3fd5f95646ce0d09852f43ff67f06f111')
    end
  end
end
