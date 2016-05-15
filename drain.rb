#!/usr/bin/env ruby

def log msg
  STDOUT.write("#{msg}\n")
  STDOUT.flush
end

log "STARTING"

def write_file name, data
  name = "NONAME" if name.nil? || name.empty?
  base_out = File.absolute_path './data'
  name_with_timestamp = "#{name}-#{Time.now.to_f}"
  out_path = File.join base_out, name_with_timestamp
  log "writing: #{name} :: #{data.length} => #{out_path}"
  File.write(out_path, data)
end

require 'rubygems'
require 'mqtt'

server_host = ARGV.shift

log "connecting to: #{server_host}"

MQTT::Client.connect(server_host) do |client|
  client.get('level/#') do |topic, message|
    log "received: [#{topic}] #{message.length}"
    _, _, tag = topic.split('/', 3)
    write_file tag, message
  end
end
