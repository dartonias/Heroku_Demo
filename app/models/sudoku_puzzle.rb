class SudokuPuzzle < ActiveRecord::Base
  default_scope { order(updated_at: :desc) }

  def self.new_puzzle(constraints, name)
    # Check if the puzzle is in the database already, and return it if it is
    constraint_string = constraints.join("")
    sample = SudokuPuzzle.where(constraints: constraint_string).first
    if sample
      sample.status = "Submitted"
      # Go with deleting the old solution to get new seeding
      # If we leave the solution, it will be used as a seed configuration
      # for the next simulation
      sample.solution = nil
      if name.size > 0
        sample.name = name
      end
      sample.save
      return sample
    else
      problem = SudokuPuzzle.new
      # Convert the constraints to a string from an array of integers
      problem.constraints = constraints.join("")
      problem.status = "Submitted"
      if name && name.size > 0
        problem.name = name
      end
      problem.save
      return problem
    end
  end

  def set_conflicts
    @row_conflicts = []
    @col_conflicts = []
    @conflicts = []
    # Only do this if the solution exists
    if self.solution && self.solution.size == 81
      data = solution_array
      (0..8).each do |i|
        # Find if the row has any duplicates
        initial = (1..9).to_a
        (0..8).each do |r|
          if !initial.delete(data[9*i+r])
            @row_conflicts << i
            duplicate = data[9*i+r]
            (0..8).each do |rr|
              if data[9*i+rr] == duplicate && !@conflicts.include?(9*i+rr)
                @conflicts << 9*i+rr
              end
            end
          end
        end
        # Find if the col has any duplicates
        initial = (1..9).to_a
        (0..8).each do |c|
          if !initial.delete(data[i+9*c])
            @col_conflicts << i
            duplicate = data[i+9*c]
            (0..8).each do |cc|
              if data[i+9*cc] == duplicate && !@conflicts.include?(i+9*cc)
                @conflicts << i+9*cc
              end
            end
          end
        end
      end
    end
  end

  def self.search(query)
    if query and query.size > 0
      where("name LIKE ? OR name LIKE ? OR name LIKE ?", "%#{query}%", "%#{query.downcase}%", "%#{query.capitalize}%")
    else
      all
    end
  end

  def is_error?(row,col)
    if !defined?(@conflicts)
      set_conflicts
    end
    #@row_conflicts.include?(row) || @col_conflicts.include?(col)
    @conflicts.include?(row*9 + col)
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

  def save_finished(solution, num_sweeps)
    self.solution = solution.join("")
    self.status = "Solved in #{num_sweeps} sweeps"
    self.save
  end

  def save_impossible
    self.status = "Impossible"
    self.save
  end

  def solved?
    /Solved/ === self.status
  end

  def impossible?
    /Impossible/ === self.status
  end

  def can_work_on?
    /errors/ === self.status
  end
end
