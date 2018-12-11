# frozen_string_literal: true

require 'spec_helper'

describe Rabbitek::Batcher do
  subject(:perform) do
    batcher.perform(*initial_message) do |messages|
      pp messages.size
    end
  end

  let(:batcher) { described_class.new(consumer, batch_size) }

  let(:consumer) { instance_double(Rabbitek::Consumer, queue: consumer_queue) }
  let(:consumer_queue) { instance_double(Bunny::Queue) }

  let(:batch_size) { 3 }

  let(:initial_message) do
    [{ 'first' => 'payload' }, instance_double(Bunny::DeliveryInfo), instance_double(Bunny::MessageProperties)]
  end
  let(:queue_messages) do
    [
      [instance_double(Bunny::DeliveryInfo), instance_double(Bunny::MessageProperties), Oj.dump('second' => 'payload')],
      [instance_double(Bunny::DeliveryInfo), instance_double(Bunny::MessageProperties), Oj.dump('third' => 'payload')]
    ]
  end
  let(:expected_batch) do
    [
      { payload: initial_message[0], delivery_info: initial_message[1], properties: initial_message[2] },
      { payload: Oj.load(queue_messages[0][2]), delivery_info: queue_messages[0][0], properties: queue_messages[0][1] },
      { payload: Oj.load(queue_messages[1][2]), delivery_info: queue_messages[1][0], properties: queue_messages[1][1] }
    ]
  end

  before do
    allow(consumer_queue).to receive(:pop).with(manual_ack: true).and_return(queue_messages[0], queue_messages[1], nil)
  end

  shared_examples_for 'yielding batch' do
    it 'yields batched messages' do
      expect { |b| batcher.perform(*initial_message, &b) }.to yield_with_args(expected_batch)
    end
  end

  context 'when reaching end of queue' do
    it_behaves_like 'yielding batch'
  end

  context 'when reaching max batch size' do
    let(:batch_size) { 2 }
    let(:expected_batch) { super().tap(&:pop) }

    it_behaves_like 'yielding batch'
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

    let(:messages_to_retry) do
      [
        [Oj.dump(initial_message[0]), initial_message[1], initial_message[2]],
        [queue_messages[0][2], queue_messages[0][0], queue_messages[0][1]],
        [queue_messages[1][2], queue_messages[1][0], queue_messages[1][1]]
      ]
    end

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
