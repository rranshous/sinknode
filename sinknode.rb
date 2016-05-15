#!/usr/bin/env ruby

require 'open3'

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
source_port = source_host.split(':',2).last || '1883'
source_host = source_host.split(':',2).first
raise "missing suorce host" if source_host.nil?
target_host = ARGV.shift
target_port = target_host.split(':',2).last || '1883'
target_host = target_host.split(':',2).first
raise "missing target_host" if target_host.nil?

# open up a subprocesses which subscribes to all level messages
sub_command = "docker run -i rranshous/mosquitto mosquitto_sub -v -h #{source_host} -p #{source_port} -t 'level/#' -q 2 -i bridge-#{our_level}-#{source_host}-#{target_host}"
puts "opening subprocesses with command: #{sub_command}"

Open3.popen3(sub_command) do |stdin, stdout, stderr, wait_thr|
  puts "reading"
  while line = stdout.readline
    puts "line: #{line}"
    if line.empty?
      puts "blank line?"
      next
    end
    puts "line: #{line}"
    topic, data = line.split " ", 2
    puts "topic: #{topic}"
    puts "data: #{data}"
    _, level = topic.split('/',3)
    level = level.to_i
    puts "level: #{level}"
    # we only accept data from nodes "higher" than us
    if level <= our_level
      puts "skipping message, too low level"
      next
    end
    # use the pub command to push this message down hill
    # maintain the topic
    pub_command = "docker run -i rranshous/mosquitto mosquitto_pub -h #{target_host} -p #{target_port} -t #{topic} -s"
    puts "opening subprocesses with command: #{pub_command}"
    pub_io = IO.popen(pub_command)
    puts "pub_io: #{pub_io}"
    puts "writing to pub_io: #{data}"
    pub_io.write(data)
    puts "done writing"
  end
end

puts "done reading lines"

