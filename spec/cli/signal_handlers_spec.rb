# frozen_string_literal: true

require 'spec_helper'

describe Rabbitek::CLI::SignalHandlers do
  describe '::setup' do
    let(:io_w_mock) { instance_double(IO) }

    before do
      allow(Signal).to receive(:trap)

      described_class.setup(io_w_mock)
    end

    it 'traps correct Signals' do
      expect(Signal).to have_received(:trap).with(:INT)
      expect(Signal).to have_received(:trap).with(:TERM)
    end
  end
end
