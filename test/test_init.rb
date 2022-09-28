ENV["CONSOLE_DEVICE"] ||= "stdout"
ENV["LOG_LEVEL"] ||= "_min"

puts RUBY_DESCRIPTION

puts
puts "TEST_BENCH_DETAIL: #{ENV["TEST_BENCH_DETAIL"].inspect}"
puts

require_relative "../init"
require "messaging/controls"
require "message_store/controls"
require "debug"

require "test_bench"; TestBench.activate

include Idempotence
