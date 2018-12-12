# frozen_string_literal: true

require 'spec_helper'

describe Rabbitek::Batcher do
  subject(:perform) { batcher.perform(initial_message) {} }

  let(:batcher) { described_class.new(consumer, batch_size) }
  let(:consumer) { instance_double(Rabbitek::Consumer) }
  let(:batch_size) { 3 }

  let(:initial_message) { message_double('first' => 'payload') }
  let(:queue_messages) { [message_double('second' => 'payload'), message_double('third' => 'payload')] }
  let(:expected_batch) { [initial_message, queue_messages[0], queue_messages[1]] }

  before do
    allow(consumer).to receive(:pop_message_manually).and_return(queue_messages[0], queue_messages[1], nil)
    allow(consumer).to receive(:ack!)
  end

  shared_examples_for 'batching' do
    it 'yields batched messages' do
      expect { |b| batcher.perform(*initial_message, &b) }.to yield_with_args(expected_batch)
    end

    it 'acks the messages' do
      perform
      expect(consumer).to have_received(:ack!).with(expected_batch.last.delivery_info)
    end
  end

  context 'when reaching end of queue' do
    it_behaves_like 'batching'
  end

  context 'when reaching max batch size' do
    let(:batch_size) { 2 }
    let(:expected_batch) { super().tap(&:pop) }

    it_behaves_like 'batching'
  end

  context 'when error is raised' do
    subject(:perform_with_exception) do
      batcher.perform(*initial_message) { raise dummy_exception_class }
    end

    let(:dummy_exception_class) do
      class DummyException < StandardError
      end
      DummyException
    end

    let(:messages_to_retry) { queue_messages }

    before do
      allow(Rabbitek::Retryer).to receive(:call)
    end

    it 'retries all messages' do
      begin
        perform_with_exception
      rescue dummy_exception_class
        nil
      end

      messages_to_retry.each { |message| expect(Rabbitek::Retryer).to have_received(:call).with(consumer, *message) }
    end

    it 'does not suppress the error' do
      expect { perform_with_exception }.to raise_error(dummy_exception_class)
    end
  end
end
