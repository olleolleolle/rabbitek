# frozen_string_literal: true

module Rabbitek
  ##
  # Log helpers
  module Loggable
    def self.logger
      Rabbitek.logger
    end

    def logger
      Rabbitek.logger
    end

    def error(msg)
      log_msg(:error, msg)
      NewRelic::Agent.notice_error(msg) if Rabbitek.config.enable_newrelic && Object.const_defined?('NewRelic')
      raven_capture_error(msg) if Rabbitek.config.enable_sentry && Object.const_defined?('Raven')
      true
    end

    def warn(msg)
      log_msg(:warn, msg)
    end

    def debug(msg)
      log_msg(:debug, msg)
    end

    def info(msg)
      log_msg(:info, msg)
    end

    private

    def log_msg(severity, msg)
      if logger.respond_to?(:tagged)
        logger.tagged(class_name(msg)) { logger.send(severity, msg) }
      else
        logger.send(severity, msg)
      end

      true
    end

    def class_name(msg)
      msg.is_a?(Hash) && msg[:class_name] ? msg.delete(:class_name) : self.class.name
    end

    def raven_capture_error(msg)
      msg.is_a?(Exception) ? Raven.capture_exception(msg) : Raven.capture_message(msg.to_s)
    end
  end
end
