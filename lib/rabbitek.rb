# frozen_string_literal: true

require 'rabbitek/version'

require 'bunny'
require 'oj'
require 'opentracing'
require 'logger'

# active_support
require 'active_support/core_ext/module/attribute_accessors'
require 'active_support/core_ext/hash/indifferent_access'
require 'active_support/core_ext/string/inflections'

current_dir = File.dirname(__FILE__)

require 'rabbitek/bunny_connection'
require 'rabbitek/cli'
require 'rabbitek/config'
require 'rabbitek/loggable'
Dir.glob("#{current_dir}/rabbitek/cli/**/*.rb").each { |file| require file }
Dir.glob("#{current_dir}/rabbitek/client/**/*.rb").each { |file| require file }
Dir.glob("#{current_dir}/rabbitek/server/**/*.rb").each { |file| require file }
Dir.glob("#{current_dir}/rabbitek/utils/**/*.rb").each { |file| require file }

##
# High performance background job processing using RabbitMQ
module Rabbitek
  def self.config
    @config ||= Config.new
  end

  def self.configure
    yield(config)
  end

  def self.reloader
    config.reloader
  end

  def self.logger
    @config.logger
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
