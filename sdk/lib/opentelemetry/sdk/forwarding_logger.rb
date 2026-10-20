# frozen_string_literal: true

require 'logger'

module OpenTelemetry
  module SDK
    # The ForwardingLogger provides a wrapper to control the OpenTelemetry
    # log level, while respecting the configured level of the supplied logger.
    # If the OTEL_LOG_LEVEL is set to debug, and the supplied logger is configured
    # with an ERROR log level, only OpenTelemetry logs at the ERROR level or higher
    # will be emitted.
    class ForwardingLogger
      def initialize(logger, level:)
        @logger = logger

        if level.is_a?(Integer)
          @level = level
        else
          case level.to_s.downcase
          when 'debug'
            @level = Logger::DEBUG
          when 'info'
            @level = Logger::INFO
          when 'warn'
            @level = Logger::WARN
          when 'error'
            @level = Logger::ERROR
          when 'fatal'
            @level = Logger::FATAL
          when 'unknown'
            @level = Logger::UNKNOWN
          else
            raise ArgumentError, "invalid log level: #{level}"
          end
        end
      end

      def add(severity, message = nil, progname = nil, &)
        return true if severity < @level

        @logger.add(severity, message, progname, &)
      end

      def debug(progname = nil, &)
        add(Logger::DEBUG, nil, progname, &)
      end

      def info(progname = nil, &)
        add(Logger::INFO, nil, progname, &)
      end

      def warn(progname = nil, &)
        add(Logger::WARN, nil, progname, &)
      end

      def error(progname = nil, &)
        add(Logger::ERROR, nil, progname, &)
      end

      def fatal(progname = nil, &)
        add(Logger::FATAL, nil, progname, &)
      end

      def unknown(progname = nil, &)
        add(Logger::UNKNOWN, nil, progname, &)
      end
    end
  end
end
