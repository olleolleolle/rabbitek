# frozen_string_literal: true

require 'spec_helper'

describe Rabbitek::Utils::Common do
  let(:channel) { instance_double(Bunny::Channel) }

  describe '.exchange' do
    let(:exchange_name) { 'yolo' }

    before do
      allow(channel).to receive(:fanout)
    end

    it 'creates exchange with correct params' do
      described_class.exchange(channel, :fanout, exchange_name)

      expect(channel).to have_received(:fanout).with(exchange_name, durable: true, auto_delete: false)
    end
  end

  describe '.queue' do
    let(:queue_name) { 'q' }

    before do
      allow(channel).to receive(:queue)
    end

    it 'creates queue with correct params' do
      described_class.queue(channel, queue_name, any_option: true)

      expect(channel).to have_received(:queue).with(queue_name, any_option: true, durable: true, auto_delete: false)
    end
  end
end
