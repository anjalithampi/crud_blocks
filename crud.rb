#!/usr/bin/env ruby

elements_count_hash = Hash.new(-1)
values_count = Hash.new(0)

ARGF.readlines.each do |str|
  line = str.split(' ')
  #puts line.inspect

  command = line[0]
  hashkey = line[1]
  hashvalue = line[2]

  #puts "COMMAND = #{command}; 1st INPUT = #{hashkey}; 2nd INPUT = #{hashvalue}\n"
  case command
  when "SET"
    # If 'value' input is empty e.g : SET a
    if hashvalue.nil?
      # if key already exists skip to next command
      # else, set key to -1 in elements hash
      elements_count_hash.key?(hashkey) ? next : elements_count_hash[hashkey] = -1
    else # If command is correct e.g: SET a 10
      # If old value is same as new value, skip to next command
      next if(elements_count_hash[hashkey] == hashvalue)
      # If key already exists, reduce count of oldvalue in values hash
      ##print("elements_count_hash.key?(#{hashkey})? = #{elements_count_hash.key?(hashkey)}\n")
      if elements_count_hash.key?(hashkey)
        oldvalue = elements_count_hash[hashkey]
        values_count[oldvalue] -= 1
        ##print("Old value = #{oldvalue}; values_count[#{oldvalue}]= #{values_count[oldvalue]}\n")
      end
      # Now set key to new value
      elements_count_hash[hashkey] = hashvalue
      values_count[hashvalue] += 1
      ##print("elements_count_hash[#{hashkey}] = #{elements_count_hash[hashkey]}\n")
      ##print("New value = #{hashvalue}; values_count[#{hashvalue}]= #{values_count[hashvalue]}\n")
    end
  when "GET"
    # If key exists, then print element value, else print "NULL"
    elements_count_hash.key?(hashkey) ? puts(elements_count_hash[hashkey]) : puts("NULL")
  when "COUNT"
    # If key exists, then print value count, else print "NULL"
    values_count.key?(hashkey) ? puts(values_count[hashkey]) : puts("NULL")
  when "DELETE"
    # If key exists in elements hash, 
    if elements_count_hash.key?(hashkey)
      value_key = elements_count_hash[hashkey]
      values_count[value_key] > 1 ? values_count[value_key] -= 1 : values_count.delete(value_key)
      ##print("\n VALUE KEY : #{value_key} and in values_count = #{values_count[value_key]}\n\n")
      elements_count_hash.delete(hashkey)
    end 
  end
  ##print("ELEMENTS = #{elements_count_hash}\n")
  ##print("VALUES = #{values_count}\n")
  ##print("-------------------------------------------\n")
end

