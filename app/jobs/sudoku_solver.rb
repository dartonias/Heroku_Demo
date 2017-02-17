class SudokuSolver
  include SuckerPunch::Job

  # Set the constraints of the simulation, or the keys specified by the user
  def perform(constraints)
    # Puzzle is 9x9, so we expect an array of 81 integers
    # For the format, we assume that the numbers are listed for each row
    # of 9 numbers, and then by column
    # Constraints pass, set internally and write initial job to database
    @constraints = check_constraints(constraints)
    db_initial
    # Initialize the simulation, and calculate initial energy
    init_sim
    # Calculate initial energy
    # Do sweeps (check energy after each step)
    # If energy zero, save solution to database
  end

  # Using active record, wrap in the below code
  #ActiveRecord::Base.connection_pool.with_connection do
  # # database code here
  #end

  private
    def check_constraints(constraints)
      if constraints.size != 81
        raise ArgumentError, "Expected constraints to have 81 elements"
      end
      for constraints.each do |v|
        if !v.is_a?(Integer)
          raise ArgumentError, "Expected elements of constraints to be integers"
        end
        if v<0 or v>9
          raise ArgumentError, "Expected elements to be in [0..9]"
        end
      end
      return constraints
    end

    def db_initial
      # Add initial problem to DB, mark as being worked on
    end

    # Helper class for indexing into @config
    # Contains a pointer to the original data config
    # so it should always reference the same data
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
      set_flippable
    end

    def set_flippable
      @flippable = []
      (0..8).each do |square|
        t = (0..8).to_a
        @flippable << t
      end
    end

    def calc_energy
      # Calculate the total energy based on the @config
    end

    def sconfig
end