# frozen_string_literal: true

require 'socket'

Thread.abort_on_exception = true
Thread.report_on_exception = false if Thread.respond_to?(:report_on_exception)

class LocalServer
  @servers ||= {}
  @mock_responses ||= {}

  class << self
    def default_response
      <<~HEREDOC
        HTTP/1.1 200 OK

        default good response
      HEREDOC
    end

    attr_reader :servers

    def mocked_responses
      @mock_responses
    end

    def save_mock(verb, path, response)
      @mock_responses["#{verb}-#{path}"] = response
    end

    def start_server(port = 31_000)
      return servers unless port_open?(port)

      @servers[port] = Thread.new do
        server = TCPServer.open(port)
        loop do
          socket = server.accept
          verb, path, _http_version = socket.gets.split(' ')
          # puts "Received verb: #{verb} path: #{path} http_version: #{_http_version}"
          while (request = socket.gets) && !request.chomp.empty?
            # puts "Incoming request headers -- \"#{request.chomp}\"" # the server logs each response
          end
          if @mock_responses["#{verb}-#{path}"].nil?
            socket.write(default_response)
          else
            socket.write(@mock_responses["#{verb}-#{path}"])
          end
          socket.close
        end
      end
    end

    def port_open?(port)
      # The great minitest runs the test repetitively, this is to avoid a previous threads already created a TCP Server

      TCPServer.open(port, &:close)
      true
    rescue Errno::EADDRINUSE => e
      puts "Error in local_server.rb: #{e}"
      false
    rescue Errno::ECONNREFUSED => e # Port is already taken by something else
      puts "Error in local_server.rb: #{e}"
      false
    rescue IOError => e # Nothing being served at this port
      puts "Error in local_server.rb: #{e}"
      true
    end

    def stop_servers
      @servers&.values&.each(&:kill)
      @servers.clear
    end
  end
end
