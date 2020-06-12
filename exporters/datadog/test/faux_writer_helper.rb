# frozen_string_literal: true

require 'ddtrace/encoding'
require 'ddtrace/tracer'
require 'ddtrace/span'

# FauxWriter is a dummy writer that buffers spans locally.
class FauxWriter < Datadog::Writer
  def initialize(options = {})
    options[:transport] ||= FauxTransport.new
    super
    @mutex = Mutex.new

    # easy access to registered components
    @spans = []
  end

  def write(trace)
    @mutex.synchronize do
      super(trace)
      @spans << trace
    end
  end

  def spans(action = :clear)
    @mutex.synchronize do
      spans = @spans
      @spans = [] if action == :clear
      spans.flatten!
      # sort the spans to avoid test flakiness
      spans.sort! do |a, b|
        if a.name == b.name
          if a.resource == b.resource
            if a.start_time == b.start_time
              a.end_time <=> b.end_time
            else
              a.start_time <=> b.start_time
            end
          else
            a.resource <=> b.resource
          end
        else
          a.name <=> b.name
        end
      end
    end
  end

  def trace0_spans
    @mutex.synchronize do
      return [] unless @spans
      return [] if @spans.empty?

      spans = @spans[0]
      @spans = @spans[1..@spans.size]
      spans
    end
  end
end

# FauxTransport is a dummy Datadog::Transport that doesn't send data to an agent.
class FauxTransport < Datadog::Transport::HTTP::Client
  def initialize(*); end

  def send_traces(*)
    # Emulate an OK response
    Datadog::Transport::HTTP::Traces::Response.new(
      Datadog::Transport::HTTP::Adapters::Net::Response.new(
        Net::HTTPResponse.new(1.0, 200, 'OK')
      )
    )
  end
end
