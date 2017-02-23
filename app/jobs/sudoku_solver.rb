class SudokuSolver
  include SuckerPunch::Job

  # Set the constraints of the simulation, or the keys specified by the user
  # sample (immediate) usage
  ###
  # constraints = (0..80).map {|a| 0}
  # test = SudokuSolver.new
  # test.perform(constraints)
  # # To run asynchronously
  # constraints = (0..80).map {|a| 0}
  # SudokuSolver.perform_async(constraints)
  ###
  def perform(obj)
    # Puzzle is 9x9, so we expect an array of 81 integers
    # For the format, we assume that the numbers are listed for each row
    # of 9 numbers, and then by column
    # Constraints pass, set internally and write initial job to database
    case obj
    when Array
      constraints = obj
      @constraints = check_constraints(constraints)
      db_initial
    when SudokuPuzzle
      @db_entry = obj
      @constraints = @db_entry.constraints_array
    end
    # Initialize the simulation, and calculate initial energy
    if !@db_entry.solved? && !@db_entry.impossible?
      @num_sweeps = (ENV['SUDOKU_NUM_SWEEPS'] || 10000).to_i
      if init_sim
        # Do sweeps (check energy after each step)
        @num_sweeps.times do
          break if do_sweep
        end
        # Save solution to database
        db_save_current
      else
        # Simulation was impossible from the start
        db_save_impossible
      end
    end
  end

  def pretty
    r = ''
    (0..8).each do |row|
      (0..8).each do |col|
        ind = row*9 + col
        r << "#{@lowest_config[ind]} "
        if (col%3)==2
          r << ' '
        end
      end
      r << "\n"
      if (row%3)==2
        r << "\n"
      end
    end
    return r
  end

  # Using active record, wrap in the below code
  #ActiveRecord::Base.connection_pool.with_connection do
  # # database code here
  #end

  private
  def check_constraints(constraints)
    if constraints.size != 81
      raise ArgumentError, "Expected constraints to have exactly 81 elements"
    end
    constraints.each do |v|
      if !v.is_a?(Integer)
        raise ArgumentError, "Expected elements of constraints to be integers"
      end
      if v<0 or v>9
        raise ArgumentError, "Expected of constraints elements to be in [0..9]"
      end
    end
    return constraints
  end

  def db_initial
    # Add initial problem to DB, mark as being worked on
    @db_entry = SudokuPuzzle.new_puzzle(@constraints)
  end

  def db_save_current
    # Save current progress or solution
    if @lowest_energy == 0
      @db_entry.save_finished(@lowest_config)
    else
      @db_entry.save_current(@lowest_config, @lowest_energy)
    end
  end

  def db_save_impossible
    @db_entry.save_impossible
  end

  # Helper class for indexing into @config
  # Contains a pointer to the original data config
  # so it should always reference the same data,
  # even as it changes
  class Sconfig
    def initialize(config)
      @config = config
    end

    def [](square,ind)
      x_offset = (square%3)*3 + ind%3
      y_offset = (square/3)*3 + ind/3
      config_ind = x_offset + 9*y_offset
      return @config[config_ind]
    end

    def []=(square,ind,val)
      x_offset = (square%3)*3 + ind%3
      y_offset = (square/3)*3 + ind/3
      config_ind = x_offset + 9*y_offset
      @config[config_ind] = val
    end
  end

  def init_sim
    # Initialize the simulation
    @config = @constraints.map {|a| a}
    @sconfig = Sconfig.new(@config)
    if calc_total_energy > 0
      # Puzzle is certainly impossible, lets not bother with it
      return false
    end
    # Flippable tells us what indices we are allowed to swap during
    # the simulation
    set_flippable
    if !fill_config
      # Puzzle had repeats in a subsquare, also unsolvable
      return false
    end
    @beta = (ENV['SUDOKU_BETA_INITIAL'] || 1.0).to_f
    @delta_beta = ((ENV['SUDOKU_BETA_FINAL'] || 10.0).to_f - @beta)/@num_sweeps
    return true
  end

  # An update roughly proportional to the size of the system
  def do_sweep
    @beta += @delta_beta
    81.times do
      square = @flippable_squares.sample
      swaps = @flippable[square].sample(2)
      break if try_swap(square, *swaps)
    end
    # Check if the energy is zero, if it is, we solved it
    if @total_energy == 0
      return true
    end
    return false
  end

  def try_swap(square, s1, s2)
    # Calculate initial row and column energy
    rows = []
    cols = []
    [s1, s2].each do |s|
      r = (square/3)*3 + s/3
      c = (square%3)*3 + s%3
      if !rows.include?(r)
        rows << r
      end
      if !cols.include?(c)
        cols << c
      end
    end
    energy_initial = 0
    rows.each do |row|
      energy_initial += row_energy(row)
    end
    cols.each do |col|
      energy_initial += col_energy(col)
    end
    # Swap
    #temp = @sconfig[square, s1]
    #@sconfig[square, s1] = @sconfig[square, s2]
    #@sconfig[square, s2] = temp
    # See if this works with the custom array methods, otherwise use the above
    @sconfig[square, s1], @sconfig[square, s2] = @sconfig[square, s2], @sconfig[square, s1]
    # Calculate final row and column energy
    energy_final = 0
    rows.each do |row|
      energy_final += row_energy(row)
    end
    cols.each do |col|
      energy_final += col_energy(col)
    end
    # Accept or reject (and unswap)
    # rand generates a random float in [0,1)
    # Could make this a faster lookup table later if needed
    if (energy_final - energy_initial) < 0 || rand < Math.exp(-1*@beta*(energy_final - energy_initial))
      # Accept the move
      @total_energy += (energy_final - energy_initial)
      check_lowest
      # Checks for zero energy
      if @total_energy == 0
        return true
      end
    else
      # Reject the move
      @sconfig[square, s1], @sconfig[square, s2] = @sconfig[square, s2], @sconfig[square, s1]
    end
    return false
  end

  def check_lowest
    if @total_energy < @lowest_energy
      @lowest_energy = @total_energy
      @lowest_config = @config.map {|a| a}
    end
  end

  def fill_config
    (0..8).each do |square|
      needed = (1..9).to_a
      (0..8).each do |elem|
        if @sconfig[square,elem] != 0
          if !needed.delete(@sconfig[square,elem])
            # This means we tried to remove a number twice from the array
            # which in turn implies the puzzle is unsolvable
            return false
          end
        end
      end
      # Go through a second time, and write over the zeros
      if @db_entry.solution.nil?
        (0..8).each do |elem|
          if @sconfig[square,elem]==0
            val = needed.sample
            # This should not be nil
            if val.nil?
              raise "This shouldnt not have happened (fill_config)"
            end
            needed.delete(val)
            @sconfig[square,elem] = val
          end
        end
      end
    end
    if !@db_entry.solution.nil?
      temp = @db_entry.solution_array
      (0..80).each do |ind|
        @config[ind] = temp[ind]
      end
    end
    calc_total_energy
    @lowest_energy = @total_energy
    @lowest_config = @config.map {|a| a}
    return true
  end

  def set_flippable
    @flippable = []
    @flippable_squares = []
    (0..8).each do |square|
      t = (0..8).to_a
      (0..8).each do |elem|
        if @sconfig[square,elem] != 0
          t.delete(elem)
        end
      end
      # If we only have one or zero elements, we can't do swapping
      if t.size < 2
        t = []
      else
        @flippable_squares << square
      end
      @flippable << t
    end
  end

  def row_energy(row)
    energy = 0
    tally = []
    (0..8).each do |col|
      ind = row*9 + col
      if @config[ind] > 0 && !tally.include?(@config[ind])
        tally << @config[ind]
      elsif tally.include?(@config[ind])
        energy += 1
      end
    end
    return energy
  end

  def col_energy(col)
    energy = 0
    tally = []
    (0..8).each do |row|
      ind = row*9 + col
      if @config[ind] > 0 && !tally.include?(@config[ind])
        tally << @config[ind]
      elsif tally.include?(@config[ind])
        energy += 1
      end
    end
    return energy
  end

  def calc_total_energy
    # Calculate the total energy based on the @config
    @total_energy = 0
    (0..8).each do |row|
      @total_energy += row_energy(row)
    end
    (0..8).each do |col|
      @total_energy += col_energy(col)
    end
    @lowest_energy = @total_energy
    return @total_energy
  end
end