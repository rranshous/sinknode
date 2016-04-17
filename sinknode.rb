#!/usr/bin/env ruby

require 'io'

# data flows down
# there are 8 levels
# each node has a level

# we are going to subscribe to all subscriptions
# and pass on those from "uphill" or a "higher" level than us

# level should be defined and be an integer
level = ARGV.shift
raise 'missing level' if level.empty?
level = level.to_i

# open up a subprocesses which subscribes to all level messages
sub_command = "mosquitto_sub -v -h #{source_host} -t level/# -q 2"
puts "opening subprocesses with command: #{sub_command}"
sub_io = IO.popen(sub_command)
puts "sub_io: #{sub_io}"

# go through the messages as we receive them
sub_io.readlines.each do |line|
  puts "line: #{line}"
  topic, data = data.split "\n", 2
  puts "topic: #{topic}"
  puts "data: #{data}"
  _, level = topic.split('/',3)
  puts "level: #{level}"
  # we only accept data from nodes "higher" than us
  if level.to_i <= level
    puts "skipping message, too low level"
    next
  end
  # use the pub command to push this message down hill
  # maintain the topic
  pub_command = "mosquitto_pub -h #{target_host} -t #{topic} -s"
  puts "opening subprocesses with command: #{pub_command}"
  pub_io = IO.popen(pub_command)
  puts "pub_io: #{pub_io}"
  puts "writing to pub_io: #{data}"
  pub_io.write(data)
  puts "done writing"
end

puts "done reading lines"
