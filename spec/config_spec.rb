# frozen_string_literal: true

require 'spec_helper'

describe Rabbitek::Config do
  subject(:config) { described_class.new }

  describe '#add_client_hook' do
    it 'adds hook by default at the last position' do
      config.add_client_hook('a')
      config.add_client_hook('sth')

      expect(config.instance_variable_get(:@client_hooks_config).last).to eq('sth')
    end

    it 'adds hook on selected position' do
      config.add_client_hook('a')
      config.add_client_hook('sth')
      config.add_client_hook('in', 1)

      expect(config.instance_variable_get(:@client_hooks_config)[1]).to eq('in')
    end
  end

  describe '#add_server_hook' do
    it 'adds hook by default at the last position' do
      config.add_server_hook('a')
      config.add_server_hook('sth')

      expect(config.instance_variable_get(:@server_hooks_config).last).to eq('sth')
    end

    it 'adds hook on selected position' do
      config.add_server_hook('a')
      config.add_server_hook('sth')
      config.add_server_hook('in', 1)

      expect(config.instance_variable_get(:@server_hooks_config)[1]).to eq('in')
    end
  end
end
