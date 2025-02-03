#!/usr/bin/env ruby
require 'json'

blocks_hash = Hash.new { |hash, key| hash[key] = Hash.new(0) }
count_hash = Hash.new { |hash, key| hash[key] = Hash.new(0) }
blocks_count = 0
block_commands = [ "BEGIN", "COMMIT", "ROLLBACK" ]
edit_commands = [ "GET", "COUNT", "DELETE" ]

ARGF.readlines.each do |str|
  line = str.split(' ')

  command = line[0].upcase
  hashkey = line[1]
  hashvalue = line[2]

  if block_commands.include?(command) && (!hashkey.nil? || !hashvalue.nil?)
    next
  end
  if edit_commands.include?(command) && (hashkey.nil? || !hashvalue.nil?)
    next
  end

  ## -- DEBUG LINES --
  ## puts "COMMAND = #{command}; 1st INPUT = #{hashkey}; 2nd INPUT = #{hashvalue}; blocks_count = #{blocks_count}\n"
  ## -- DEBUG LINES --

  case command
  when "BEGIN"
    if blocks_hash[blocks_count].empty?
      blocks_hash[blocks_count + 1] = Hash.new(0)
      count_hash[blocks_count] = Hash.new(0)
      count_hash[blocks_count + 1] = Hash.new(0)
    else
      blocks_hash[blocks_count + 1] = JSON.parse(blocks_hash[blocks_count].to_json, symbolize_names: false)
      count_hash[blocks_count + 1] = JSON.parse(count_hash[blocks_count].to_json, symbolize_names: false)
    end
    blocks_count += 1
  when "COMMIT"
    if blocks_count.zero?
      puts "ERROR! No corresponding BEGIN block!"
      next
    end
    blocks_hash[blocks_count - 1] = JSON.parse(blocks_hash[blocks_count].to_json, symbolize_names: false)
    count_hash[blocks_count - 1] = JSON.parse(count_hash[blocks_count].to_json, symbolize_names: false)
    blocks_hash[blocks_count] = {}
    count_hash[blocks_count] = {}
    blocks_count -= 1

  when "ROLLBACK"
    if blocks_count.zero?
      puts "ERROR! No corresponding BEGIN block!"
      next
    end
    blocks_hash[blocks_count] = {}
    count_hash[blocks_count] = {}
    blocks_count -= 1

  when "SET"
    # If 'value' input is empty e.g : SET a
    if hashvalue.nil?
      # if key already exists skip to next command
      next
    else # If command is correct e.g: SET a 10
      next if(blocks_hash[blocks_count][hashkey] == hashvalue) # If old value is same as new value, skip to next command

      if count_hash[blocks_count].key?(hashvalue) # If hashalue already exists in count_hash, reduce its count
        count_hash[blocks_count][hashvalue] += 1
      elsif blocks_hash[blocks_count].key?(hashkey) # If hashkey already exists in blocks_hash, reduce its count ; adjust count_hash keys' values
        oldvalue = blocks_hash[blocks_count][hashkey]
        count_hash[blocks_count][oldvalue] -= 1
        count_hash[blocks_count][hashvalue] = 1
      else # If neither hashkey exists in blocks_hash nor hashvalue exists in count_hash
        count_hash[blocks_count][hashvalue] = 1
      end

      blocks_hash[blocks_count][hashkey] = hashvalue # Now set key to new value
    end

  when "GET"
    # If key exists, then print element value, else print "NULL"
    blocks_hash[blocks_count].key?(hashkey) ? puts(blocks_hash[blocks_count][hashkey]) : puts("NULL")

  when "COUNT"
    # If key exists, then print value count, else print "NULL"
    count_hash[blocks_count].key?(hashkey) ? puts(count_hash[blocks_count][hashkey]) : puts("NULL")

  when "DELETE"
    # If key exists in elements hash
    if blocks_hash[blocks_count].key?(hashkey)
      value_key = blocks_hash[blocks_count][hashkey]
      count_hash[blocks_count][value_key] > 1 ? count_hash[blocks_count][value_key] -= 1 : count_hash[blocks_count].delete(value_key)
      blocks_hash[blocks_count].delete(hashkey)
      #puts "Deleted #{hashkey}"
    #else
      #puts("#{hashkey} not present! Not deleted!")
    end
  end

  ## -- DEBUG LINES --
  ## print("\nFULL BLOCK LIST = #{blocks_hash}\n")
  ## print("VALUES = #{count_hash}\n")
  ## print("----------------------------------------------------------------\n")
  ## -- DEBUG LINES --
end
