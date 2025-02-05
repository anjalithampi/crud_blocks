#!/usr/bin/env ruby
require 'json'

# Stack for blocks - each element is a hash of key-value pairs 
blocks_stack = [Hash.new]  # Block elements and their values
count_stack = [Hash.new(0)]  # Count of values for the corresponding block elements

## -- DEBUG LINES --
## puts "NEW block and count stack"
## -- DEBUG LINES --

# Only first argument; second and third is empty
block_commands = ["BEGIN", "COMMIT", "ROLLBACK"]
# Only first and second arguments; third is empty
edit_commands = ["GET", "COUNT", "DELETE"]

ARGF.readlines.each do |line| # Read file line by line
  command, blockkey, blockvalue = line.split(' ').map(&:strip)  # Parse the line

  ## -- DEBUG LINES --
  ## puts "FULL BLOCK LIST = #{blocks_stack}"
  ## puts "VALUES = #{count_stack}"
  ## puts "----------------------------------------------------------------"
  ## puts "COMMAND = #{command}; 1st INPUT = #{blockkey}; 2nd INPUT = #{blockvalue}"
  ## -- DEBUG LINES --

  # If first argument is missing
  next if command.nil?

  # Discard current & proceed to next command if
  # second and third arguments exist (e.g., COMMIT 10)
  next if block_commands.include?(command) && (!blockkey.nil? || !blockvalue.nil?)

  # Discard current & proceed to next command if
  # second argument is missing or third argument exists (e.g., COUNT 10 a)
  next if edit_commands.include?(command) && (blockkey.nil? || !blockvalue.nil?)

  # Switch case for arguments
  case command.upcase
  when "BEGIN"
    # Only duplicate necessary state changes
    blocks_stack.push(blocks_stack.last.dup)
    count_stack.push(count_stack.last.dup)

  when "COMMIT"
    if blocks_stack.size == 1
      # Display warning if paired "BEGIN" command was not set
      warn "Error: No matching BEGIN found"
      next
    end

    # Merging values into previous block
    commit_block = blocks_stack.pop
    commit_count = count_stack.pop

    blocks_stack.last.merge!(commit_block)
    count_stack.last.merge!(commit_count)

  when "ROLLBACK"
      # Display warning if paired "BEGIN" command was not set
    if blocks_stack.size == 1
      warn "Error: No matching BEGIN found"
      next
    end

    # Discard the top stack
    blocks_stack.pop
    count_stack.pop

  when "SET"
    # Discard if value is nil
    next if blockvalue.nil?

    current_block = blocks_stack.last
    current_count = count_stack.last

    # Fix the count of current and new values of key
    old_value = current_block[blockkey]
    next if old_value == blockvalue

    # Avoiding -1 as key in count_stack
    current_count[old_value] -= 1 unless old_value.nil?
    # Delete key from count_stack if count reaches 0
    current_count.delete(old_value) if current_count[old_value] <= 1

    # Update key-value in block stack
    current_block[blockkey] = blockvalue
    current_count[blockvalue] += 1

  when "GET"
    puts blocks_stack.last[blockkey] || "NULL"

  when "COUNT"
    puts count_stack.last[blockkey].zero? ? "NULL" : count_stack.last[blockkey]

  when "DELETE"
    current_block = blocks_stack.last
    current_count = count_stack.last

    if current_block.key?(blockkey)
      current_value = current_block.delete(blockkey)
      current_count[current_value] -= 1 if current_count[current_value] >= 1
      current_count.delete(current_value) if current_count[current_value].zero?
    end
  end
end
