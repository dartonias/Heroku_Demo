class SudokuPuzzle < ActiveRecord::Base
  default_scope { order(updated_at: :desc) }

  def self.new_puzzle(constraints)
    # Check if the puzzle is in the database already, and return it if it is
    constraint_string = constraints.join("")
    sample = SudokuPuzzle.where(constraints: constraint_string).first
    if sample
      sample.touch
      return sample
    else
      problem = SudokuPuzzle.new
      # Convert the constraints to a string from an array of integers
      problem.constraints = constraints.join("")
      problem.status = "Submitted"
      problem.save
      return problem
    end
  end

  def set_conflicts
    @row_conflicts = []
    @col_conflicts = []
    # Only do this if the solution exists
    if self.solution && self.solution.size == 81
      data = solution_array
      (0..8).each do |i|
        # Find if the row has any duplicates
        initial = (1..9).to_a
        (0..8).each do |r|
          if !initial.delete(data[9*i+r])
            @row_conflicts << i
          end
        end
        # Find if the col has any duplicates
        initial = (1..9).to_a
        (0..8).each do |c|
          if !initial.delete(data[i+9*c])
            @col_conflicts << i
          end
        end
      end
    end
  end

  def is_error?(row,col)
    if !defined?(@row_conflicts)
      set_conflicts
    end
    @row_conflicts.include?(row) || @col_conflicts.include?(col)
  end

  def solution_array
    self.solution.split("").map {|i| i.to_i} if self.solution
  end

  def constraints_array
    self.constraints.split("").map {|i| i.to_i}
  end

  def save_current(solution, num_errors=-1)
    self.solution = solution.join("")
    self.status = "Could not find solution, #{num_errors} errors"
    self.save
  end

  def save_finished(solution)
    self.solution = solution.join("")
    self.status = "Solved"
    self.save
  end

  def save_impossible
    self.status = "Impossible"
    self.save
  end

  def solved?
    self.status == "Solved"
  end

  def impossible?
    self.status == "Impossible"
  end
end
