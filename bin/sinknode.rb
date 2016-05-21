#!/usr/bin/env ruby

def log msg
  STDOUT.write("#{msg}\n")
  STDOUT.flush
end

log "STARTING"

require 'rubygems'
require 'mqtt'

# data flows down
# there are 8 levels
# each node has a level

# we are going to subscribe to all subscriptions
# and pass on those from "uphill" or a "higher" level than us

# level should be defined and be an integer
our_level = ARGV.shift
raise 'missing level' if our_level.nil?
our_level = our_level.to_i
source_host = ARGV.shift
source_host, source_port = source_host.split(':',2)
source_port ||= '1883'
raise "missing suorce host" if source_host.nil?
target_host = ARGV.shift
target_host, target_port = target_host.split(':',2)
target_port ||= '1883'
raise "missing target_host" if target_host.nil?

log "starting sinknode: #{source_host}:#{source_port} =(#{our_level})> " +
     "#{target_host}:#{target_port}"

loop do
  begin
    # publisher
    log "connecting to publisher"
    MQTT::Client.connect(host: target_host, port: target_port.to_i) do |publisher|
      # subscriber
      log "connecting to subscriber"
      MQTT::Client.connect(host: source_host, port: source_port.to_i) do |receiver|
        receiver.get('level/#') do |topic, message|
          log "received: [#{topic}] #{message.length}"
          level = topic.split('/', 2).last
          if level.to_i < our_level
            log "msg too low level, ignoring: [#{topic}] #{message.length}"
          else
            log "publishing: [#{topic}] #{message.length}"
            publisher.publish(topic, message)
          end
        end
      end
    end
  rescue Exception => ex
    puts "EXCEPTION: #{ex}"
    puts "restarting in 10 seconds"
    sleep 10
    retry
  end
end
