require 'logger'

module OpenTelemetry
  module SDK
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

      def debug(progname = nil, &block)
        return true if Logger::DEBUG < @level
        @logger.debug(progname, &block)
      end

      def info(progname = nil, &block)
        return true if Logger::INFO < @level
        @logger.info(progname, &block)
      end

      def warn(progname = nil, &block)
        return true if Logger::WARN < @level
        @logger.warn(progname, &block)
      end

      def error(progname = nil, &block)
        return true if Logger::ERROR < @level
        @logger.error(progname, &block)
      end

      def fatal(progname = nil, &block)
        return true if Logger::FATAL < @level
        @logger.fatal(progname, &block)
      end

      def unknown(progname = nil, &block)
        return true if Logger::UNKNOWN < @level
        @logger.unknown(progname, &block)
      end
    end
  end
end
