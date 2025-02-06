#!/usr/bin/env ruby

class TransactionalKeyValueStore

  # Initialize stack for blocks & value counts - each element is a hash of key-value pairs
  def initialize
    @blocks_stack = [Hash.new] # Block elements and their values
    @count_stack = [Hash.new(0)] # Count of values for the corresponding block elements
  end

  # Begins a new transaction block
  def begin_block
    # Only duplicate necessary state changes
    @blocks_stack.push(@blocks_stack.last.dup)
    @count_stack.push(@count_stack.last.dup)
  end

  # Commits the current transaction block
  def commit_block
    if @blocks_stack.size == 1
      # Display warning if paired "BEGIN" command was not set
      warn "Error: No active transaction to commit"
      return
    end

    # Merging values into previous block
    commit_block = @blocks_stack.pop
    commit_count = @count_stack.pop

    @blocks_stack.last.merge!(commit_block)
    @count_stack.last.merge!(commit_count)
  end

  # Rolls back to the last transaction block
  def rollback_block
    # Display warning if paired "BEGIN" command was not set
    if @blocks_stack.size == 1
      warn "Error: No active transaction to rollback"
      return
    end

    # Discard the top stack
    @blocks_stack.pop
    @count_stack.pop
  end

  # Sets the given key to the given value
  def set(blockkey, blockvalue)
    current_block = @blocks_stack.last
    current_count = @count_stack.last

    # Adjust count of previous value
    old_value = current_block[blockkey]
    return if old_value == blockvalue # No need to update if values are the same

    if old_value
      current_count[old_value] -= 1 # Avoiding -1 as key in @count_stack
      current_count.delete(old_value) if current_count[old_value] <= 1 # Delete key from @count_stack if count reaches 0
    end

    # Update key-value in block stack
    current_block[blockkey] = blockvalue
    current_count[blockvalue] += 1
  end

  # Retrieves the value of the given key
  def get(blockkey)
    puts @blocks_stack.last.fetch(blockkey, "NULL")
  end

  # Returns the count of the occurances of the given value
  def count(blockkey)
    puts @count_stack.last[blockkey].zero? ? "NULL" : @count_stack.last[blockkey]

  end

  # Deletes the given key from the current transaction block
  def delete(blockkey)
    current_block = @blocks_stack.last
    current_count = @count_stack.last

    if current_block.key?(blockkey)
      current_value = current_block.delete(blockkey)
      current_count[current_value] -= 1 if current_count[current_value] >= 1
      current_count.delete(current_value) if current_count[current_value].zero?
    end
  end

  def valid_command?(command, blockkey, blockvalue)
    # Only first argument; second and third is empty
    block_commands = ["BEGIN", "COMMIT", "ROLLBACK"]
    # Only first and second arguments; third is empty
    edit_commands = ["GET", "COUNT", "DELETE"]

    ## -- DEBUG LINES --
    ## puts "FULL BLOCK LIST = #{@blocks_stack}"
    ## puts "VALUES = #{@count_stack}\n"
    ## puts "----------------------------------------------------------------"
    ## puts "COMMAND = #{command}; 1st INPUT = #{blockkey}; 2nd INPUT = #{blockvalue}\n"
    ## -- DEBUG LINES --

    case command
    when "BEGIN", "COMMIT", "ROLLBACK"
      return blockkey.nil? && blockvalue.nil?
    when "GET", "COUNT", "DELETE"
      return !blockkey.nil? && blockvalue.nil?
    when "SET"
      return !blockkey.nil? && !blockvalue.nil?
    end

    # Returns if arguments are invalid
    false
  end

  # Processes the command line input
  def process_command(line)
    command, blockkey, blockvalue = line.split(' ').map(&:strip) # Parse the line

    # If first argument is missing
    return if command.nil?

    return unless valid_command?(command, blockkey, blockvalue)

    # Switch case for valid commands
    case command.upcase
    when "BEGIN"    then begin_block
    when "COMMIT"   then commit_block
    when "ROLLBACK" then rollback_block
    when "SET"      then set(blockkey, blockvalue)
    when "GET"      then get(blockkey)
    when "COUNT"    then count(blockkey)
    when "DELETE"   then delete(blockkey)
    end
  end
end

# Instantiate the transactionl key value store and process input commands
command_line = TransactionalKeyValueStore.new
ARGF.readlines.each do |line| # Read file line by line
  command_line.process_command(line)
end
