# frozen_string_literal: true

require 'rabbitek/version'

require 'bunny'
require 'oj'
require 'opentracing'
require 'logger'

# active_support
require 'active_support/core_ext/hash/indifferent_access'
require 'active_support/core_ext/string/inflections'

current_dir = File.dirname(__FILE__)

Dir.glob("#{current_dir}/rabbitek/*.rb").each { |file| require file }
Dir.glob("#{current_dir}/rabbitek/**/*.rb").each { |file| require file }

##
# High performance background job processing using RabbitMQ
module Rabbitek
  def self.config
    @config ||= Config.new
  end

  def self.configure
    yield(config)
  end

  def self.logger
    @logger ||= Logger.new(STDOUT)
  end

  def self.create_channel
    bunny_connection.create_channel
  end

  def self.close_bunny_connection
    bunny_connection.close
  end

  def self.bunny_connection
    @bunny_connection ||= BunnyConnection.initialize_connection
  end
end
