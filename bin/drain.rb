#!/usr/bin/env ruby

require 'rubygems'
require 'mqtt'
require 'fileutils'

def log msg
  STDOUT.write("#{msg}\n")
  STDOUT.flush
end

log "STARTING"

def write_file name, data
  is_retry = false
  name = "NONAME" if name.nil? || name.empty?
  base_out = File.absolute_path './data'
  timestamp = Time.now.to_f.to_s
  out_path = File.join base_out, name, timestamp
  log "writing: #{name} :: #{data.length} => #{out_path}"
  File.write(out_path, data)
rescue Errno::ENOENT
  raise if is_retry
  FileUtils.mkdir_p File.dirname(out_path)
  is_retry = true
  retry
end

server_host = ARGV.shift

log "connecting to: #{server_host}"

MQTT::Client.connect(server_host) do |client|
  client.get('level/#') do |topic, message|
    log "received: [#{topic}] #{message.length}"
    _, _, tag = topic.split('/', 3)
    write_file tag, message
  end
end
