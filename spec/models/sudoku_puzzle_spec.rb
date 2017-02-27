require 'rails_helper'

puzzle_input = [[0]*81,'solvable']
constraints_array = puzzle_input[0]
# Example solution for the unconstrained puzzle above, contains no errors
solution_str = "479586213315472986628319574892643157134957862567821349753268491946135728281794635"
solution_array = solution_str.split("").map {|i| i.to_i}
failed_solution = "819752346523641879674893251352967184186345792947128635431279568268534917795816423"
failures = [[1,4],[2,3],[4,4],[8,3]]

# failures are shown below, with zero indexing into (row,col)
# 819 752 346
# 523 641 879
# 674 893 251

# 352 967 184
# 186 345 792
# 947 128 635

# 431 279 568
# 268 534 917
# 795 816 423

RSpec.describe SudokuPuzzle, type: :model do
  it "responds to class method new_puzzle" do
    expect(SudokuPuzzle).to respond_to(:new_puzzle)
  end
  it "responds to class method search" do
    expect(SudokuPuzzle).to respond_to(:search)
  end
  subject(:puzzle){SudokuPuzzle.new_puzzle(*puzzle_input)}
  it "responds to instance method set_conflicts" do
    is_expected.to respond_to(:set_conflicts)
  end
  it "responds to instance method is_error?" do
    is_expected.to respond_to(:is_error?)
  end
  it "reports no errors in the case of a solved puzzle" do
    puzzle.solution = solution_str
    (0..8).each do |row|
      (0..8).each do |col|
        expect(puzzle.is_error?(row,col)).to be(false)
      end
    end
  end
  it "reports errors in the case of an unsolved puzzle" do
    puzzle.solution = failed_solution
    (0..8).each do |row|
      (0..8).each do |col|
        if failures.include?([row,col])
          expect(puzzle.is_error?(row,col)).to be(true)
        else
          expect(puzzle.is_error?(row,col)).to be(false)
        end
      end
    end
  end
  it "responds to instance method solution_array" do
    is_expected.to respond_to(:solution_array)
    puzzle.solution = solution_str
    expect(puzzle.solution_array).to eq(solution_array)
  end
  it "responds to instance method constraints_array" do
    is_expected.to respond_to(:constraints_array)
    expect(puzzle.constraints_array).to eq(constraints_array)
  end
  it "responds to instance method save_current" do
    is_expected.to respond_to(:save_current)
    num_errors = 2
    puzzle.save_current(solution_array,num_errors)
    expect(puzzle.solution).to eq(solution_str)
    expect(puzzle.status).to match(/errors/)
    expect(puzzle.status).to match(/#{num_errors}/)
    expect(SudokuPuzzle.count).to eq(1)
  end
  it "responds to instance method save_finished" do
    is_expected.to respond_to(:save_finished)
    num_sweeps = 1234
    puzzle.save_finished(solution_array, num_sweeps)
    expect(puzzle.solution).to eq(solution_str)
    expect(puzzle.status).to match(/Solved/)
    expect(puzzle.status).to match(/#{num_sweeps}/)
    expect(SudokuPuzzle.count).to eq(1)
  end
  it "responds to instance method save_impossible" do
    is_expected.to respond_to(:save_impossible)
    puzzle.save_impossible
    expect(puzzle.status).to match(/Impossible/)
    expect(SudokuPuzzle.count).to eq(1)
  end
  it "responds to instance method solved?" do
    is_expected.to respond_to(:solved?)
    expect(puzzle.solved?).to be false
    num_sweeps = 1234
    puzzle.save_finished(solution_array, num_sweeps)
    expect(puzzle.solved?).to be true
  end
  it "responds to instance method impossible?" do
    is_expected.to respond_to(:impossible?)
    expect(puzzle.impossible?).to be false
    puzzle.save_impossible
    expect(puzzle.impossible?).to be true
  end
  it "responds to instance method can_work_on?" do
    is_expected.to respond_to(:can_work_on?)
    expect(puzzle.can_work_on?).to be false
    num_errors = 2
    puzzle.save_current(solution_array,num_errors)
    expect(puzzle.can_work_on?).to be true
  end
end
