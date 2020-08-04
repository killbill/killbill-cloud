# frozen_string_literal: true

require 'spec_helper'

describe KPM::NexusFacade::Actions do
  subject { described_class.new({}, nil, logger) }
  let(:logger) { Logger.new(STDOUT) }
  let(:nexus_mock) { double(KPM::NexusFacade::NexusApiCallsV2) }

  before do
    allow(KPM::NexusFacade::NexusApiCallsV2).to receive(:new).and_return(nexus_mock)
  end

  context 'when Nexus throws a non-retryable exception' do
    it 'never retries' do
      calls = 0
      expect do
        subject.send(:retry_exceptions, 'foo') do
          calls += 1
          raise StandardError, '404'
        end
      end.to raise_error(StandardError)
      expect(calls).to eq(1)
    end
  end

  context 'when Nexus throws a retryable exception' do
    it 'retries until giving up' do
      calls = 0
      expect do
        subject.send(:retry_exceptions, 'foo') do
          calls += 1
          raise KPM::NexusFacade::UnexpectedStatusCodeException, 503
        end
      end.to raise_error(StandardError)
      expect(calls).to eq(3)
    end
  end

  context 'when networking is flaky' do
    it 'retries until call succeeds' do
      calls = 0
      expect(subject.send(:retry_exceptions, 'foo') do
        calls += 1
        raise OpenSSL::SSL::SSLErrorWaitReadable if calls < 2

        true
      end).to be_truthy
      expect(calls).to eq(2)
    end
  end
end
