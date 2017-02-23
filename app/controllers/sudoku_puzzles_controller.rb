class SudokuPuzzlesController < ApplicationController

  def index
    # Default ordering sorts by most recent
    @recent_puzzles = SudokuPuzzle.all.limit(25)

    respond_to do |format|
      format.html
      format.json
    end
  end

  def create
    set_constraints
    puzzle = SudokuPuzzle.new_puzzle(@constraints)
    SudokuSolver.perform_async(puzzle)
    redirect_to sudoku_path
  end

  def set_constraints
    if params["constraints"]
      @constraints = []
      (0..80).each do |i|
        if params["constraints"][i.to_s]
          temp = params["constraints"][i.to_s].to_i
          if temp >= 0 && temp <= 9
            @constraints << temp
          end
        else
          @constraints = nil
        end
      end
    else
      @constraints = nil
    end
  end
end
