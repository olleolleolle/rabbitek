# frozen_string_literal: true

require 'spec_helper'

describe Rabbitek::Publisher do
  let(:channel) { instance_double(Bunny::Channel) }
  let(:exchange) { instance_double(Bunny::Exchange) }
  let(:example_payload) { { test: 20 } }
  subject { described_class.new(exchange) }

  before do
    allow(Rabbitek).to receive(:create_channel).and_return(channel)
  end

  describe '#publish' do
    before do
      allow(channel).to receive(:direct).and_return(exchange)
      allow(exchange).to receive(:publish)

      subject.publish(example_payload, routing_key: 42)
    end

    it 'publishes payload with jsonifying' do
      expect(exchange).to have_received(:publish)
        .with(Oj.dump(example_payload, mode: :compat), routing_key: 42, headers: {})
    end
  end

  describe '#close' do
    before do
      allow(channel).to receive(:close)

      subject.close
    end

    it 'closes channel' do
      expect(channel).to have_received(:close)
    end
  end
end
