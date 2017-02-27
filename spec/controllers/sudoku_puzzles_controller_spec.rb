require 'rails_helper'

constraints_data = {}
(0..80).each do |i|
  constraints_data[i.to_s] = "0"
end

solution_str = "479586213315472986628319574892643157134957862567821349753268491946135728281794635"

puzzle = {constraints: "0"*81,
solution: solution_str,
status: "Solved in 2 steps",
name: "Tester"
}

# Should be larger than 25
puzzle_num = 30
puzzle_array = []
(1..puzzle_num).each do |i|
  elem = {}
  puzzle.each do |key,val|
    elem[key] = val.dup
  end
  elem[:constraints][i] = solution_str[i]
  if i > puzzle_num/2
    elem.delete(:name)
  end
  puzzle_array << elem
end

RSpec.describe SudokuPuzzlesController, type: :controller do
  it "responds to index" do
    is_expected.to respond_to(:index)
    SudokuPuzzle.create!(puzzle_array)
    expect(SudokuPuzzle.all.count).to eq(puzzle_array.size)
    get :index
    expect(assigns(:recent_puzzles).size).to eq(25)
    get :index, {:limit => '10'}
    expect(assigns(:recent_puzzles).size).to eq(10)
    get :index, {:search => 'Tester'}
    expect(assigns(:recent_puzzles).size).to eq(15)
  end
  it "responds to set_constraints" do
    is_expected.to respond_to(:set_constraints)
  end
  it "responds to create" do
    is_expected.to respond_to(:create)
    # Catch SudokuSolver.perform_async(puzzle)
    allow(SudokuSolver).to receive(:perform_async).with(anything)
    # Implicitly also testing set_constraints
    post :create, {:constraints => constraints_data}
    expect(assigns(:constraints)).to eq([0]*81)
    post :create, {:constraints_str => "1" + "0"*80}
    expect(assigns(:constraints)).to eq([1] + [0]*80)
    post :create
    expect(assigns(:constraints)).to be nil
  end
end
