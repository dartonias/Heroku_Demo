require 'rails_helper'

puzzle = [[0]*81,'solvable']
constraints_array = puzzle[0]
solution_str = "479586213315472986628319574892643157134957862567821349753268491946135728281794635"
solution_array = solution_str.split("").map {|i| i.to_i}

RSpec.describe SudokuPuzzle, type: :model do
  it "responds to class method new_puzzle" do
    expect(SudokuPuzzle).to respond_to(:new_puzzle)
  end
  it "responds to class method search" do
    expect(SudokuPuzzle).to respond_to(:search)
  end
  subject {SudokuPuzzle.new_puzzle(*puzzle)}
  it "responds to instance method set_conflicts" do
    is_expected.to respond_to(:set_conflicts)
  end
  it "responds to instance method is_error?" do
    is_expected.to respond_to(:is_error?)
    subject.solution = solution_str
    (0..8).each do |row|
      (0..8).each do |col|
        expect(subject.is_error?(row,col)).to be(false)
      end
    end
  end
  it "responds to instance method solution_array" do
    is_expected.to respond_to(:solution_array)
    subject.solution = solution_str
    expect(subject.solution_array).to eq(solution_array)
  end
  it "responds to instance method constraints_array" do
    is_expected.to respond_to(:constraints_array)
    expect(subject.constraints_array).to eq(constraints_array)
  end
  it "responds to instance method save_current" do
    is_expected.to respond_to(:save_current)
    num_errors = 2
    subject.save_current(solution_array,num_errors)
    expect(subject.solution).to eq(solution_str)
    expect(subject.status).to match(/errors/)
    expect(subject.status).to match(/#{num_errors}/)
    expect(SudokuPuzzle.count).to eq(1)
  end
  it "responds to instance method save_finished" do
    is_expected.to respond_to(:save_finished)
    num_sweeps = 1234
    subject.save_finished(solution_array, num_sweeps)
    expect(subject.solution).to eq(solution_str)
    expect(subject.status).to match(/Solved/)
    expect(subject.status).to match(/#{num_sweeps}/)
    expect(SudokuPuzzle.count).to eq(1)
  end
  it "responds to instance method save_impossible" do
    is_expected.to respond_to(:save_impossible)
    subject.save_impossible
    expect(subject.status).to match(/Impossible/)
    expect(SudokuPuzzle.count).to eq(1)
  end
  it "responds to instance method solved?" do
    is_expected.to respond_to(:solved?)
    expect(subject.solved?).to be false
    num_sweeps = 1234
    subject.save_finished(solution_array, num_sweeps)
    expect(subject.solved?).to be true
  end
  it "responds to instance method impossible?" do
    is_expected.to respond_to(:impossible?)
    expect(subject.impossible?).to be false
    subject.save_impossible
    expect(subject.impossible?).to be true
  end
  it "responds to instance method can_work_on?" do
    is_expected.to respond_to(:can_work_on?)
    expect(subject.can_work_on?).to be false
    num_errors = 2
    subject.save_current(solution_array,num_errors)
    expect(subject.can_work_on?).to be true
  end
end
