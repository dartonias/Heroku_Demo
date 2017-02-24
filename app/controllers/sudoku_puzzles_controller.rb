class SudokuPuzzlesController < ApplicationController

  def index
    # Default ordering sorts by most recent
    limit = (params["limit"] || 25).to_i
    @recent_puzzles = SudokuPuzzle.search(params[:search]).limit(limit)

    respond_to do |format|
      format.html
      format.json
    end
  end

  def create
    set_constraints
    if @constraints
      puzzle = SudokuPuzzle.new_puzzle(@constraints, params["name"])
      SudokuSolver.perform_async(puzzle)
    end
    redirect_to sudoku_path
  end

  def set_constraints
    if params["constraints"]
      @constraints = []
      (0..80).each do |i|
        if params["constraints"][i.to_s]
          temp = params["constraints"][i.to_s].to_i
          if temp >= 1 && temp <= 9
            @constraints << temp
          else
            @constraints << 0
          end
        else
          @constraints = nil
        end
      end
    elsif params["constraints_str"]
      @constraints = params["constraints_str"].split("").map {|i| i.to_i}
    else
      @constraints = nil
    end
  end
end
