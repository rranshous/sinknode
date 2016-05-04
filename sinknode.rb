#!/usr/bin/env ruby

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
raise "missing suorce host" if source_host.nil?
target_host = ARGV.shift
raise "missing target_host" if target_host.nil?

# open up a subprocesses which subscribes to all level messages
sub_command = "docker run -i rranshous/mosquitto mosquitto_sub -v -h #{source_host} -t 'level/#' -q 2 -i bridge-#{our_level}-#{source_host}-#{target_host}"
puts "opening subprocesses with command: #{sub_command}"
sub_io = IO.popen(sub_command)
puts "sub_io: #{sub_io}"

# go through the messages as we receive them
puts "reading lines"
while line = sub_io.readline do
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
  pub_command = "docker run -i rranshous/mosquitto mosquitto_pub -h #{target_host} -t #{topic} -s"
  puts "opening subprocesses with command: #{pub_command}"
  pub_io = IO.popen(pub_command)
  puts "pub_io: #{pub_io}"
  puts "writing to pub_io: #{data}"
  pub_io.write(data)
  puts "done writing"
end

puts "detaching"
Process.detach(sub_io.pid)

puts "done reading lines"

at_exit { puts "exiting"; Process.kill(sub_io) }
