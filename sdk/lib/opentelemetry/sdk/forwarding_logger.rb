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

      def add(severity, message = nil, progname = nil)
        return true if severity < @level
        @logger.add(severity, message, progname)
      end

      def debug(progname = nil, &block)
        add(Logger::DEBUG, nil, progname, &block)
      end

      def info(progname = nil, &block)
        add(Logger::INFO, nil, progname, &block)
      end

      def warn(progname = nil, &block)
        add(Logger::WARN, nil, progname, &block)
      end

      def error(progname = nil, &block)
        add(Logger::ERROR, nil, progname, &block)
      end

      def fatal(progname = nil, &block)
        add(Logger::FATAL, nil, progname, &block)
      end

      def unknown(progname = nil, &block)
        add(Logger::UNKNOWN, nil, progname, &block)
      end
    end
  end
end
