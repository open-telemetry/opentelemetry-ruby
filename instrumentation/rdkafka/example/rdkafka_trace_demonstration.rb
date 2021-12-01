require 'bundler/inline'
require 'securerandom'

gemfile(true) do
  source 'https://rubygems.org'

  gem "rdkafka", '0.10.0'
  gem 'opentelemetry-instrumentation-rdkafka', path: '../'
end

host = ENV.fetch('TEST_KAFKA_HOST') { '127.0.0.1' }
port = ENV.fetch('TEST_KAFKA_PORT') { 9092 }
server = "#{host}:#{port}"

rand_hash = SecureRandom.hex(10)

producer_config = {:"bootstrap.servers" => server}
producer = Rdkafka::Config.new(producer_config).producer
delivery_handles = []

5.times do |i|
  puts "Producing message #{i}"
  delivery_handles << producer.produce(
    topic:   "ruby-test-topic-#{rand_hash}",
    payload: "Payload #{i}",
    key:     "Key #{i}"
  )
end

delivery_handles.each(&:wait)


consumer_config = {
  :"bootstrap.servers" => server,
  :"group.id" => "ruby-test",
  :"auto.offset.reset" => 'smallest',
}
consumer = Rdkafka::Config.new(consumer_config).consumer
consumer.subscribe("ruby-test-topic-#{rand_hash}")

received_message_count = 0

consumer.each do |message|
  puts "Message received: #{message}"
  received_message_count += 1

  break if received_message_count == 5
end
