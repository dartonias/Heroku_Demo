require 'rails_helper'

# Set the random number seed to ensure that everything will be consistent
srand(1234)
easy_constraints = (0..80).map {|a| 0}
easy_solution = "426815397538729614971643825863154972754298136219367548142536789385972461697481253"
# Hardest puzzle, which tends not to be solved by the simulation
hard_constraints = "
800 000 000
003 600 000
070 090 200

050 007 000
000 045 700
000 100 030

001 000 068
008 500 010
090 000 400
"
hard_constraints.tr!(' ','')
hard_constraints.tr!("\n",'')
hard_constraints = hard_constraints.split("").map {|i| i.to_i}
hard_solution = "819752346523641879674893251352967184186345792947128635431279568268534917795816423"

RSpec.describe SudokuSolver, type: :job do
  # Simulation is a bit long, so we want to only run it once
  before(:all) do
    #Reduce number of steps to speed things up a bit
    @old_env = ENV['SUDOKU_NUM_SWEEPS']
    ENV['SUDOKU_NUM_SWEEPS'] = '1000'
    @easy_puzzle = SudokuPuzzle.new_puzzle(easy_constraints,'easy')
    @easy_sim = SudokuSolver.new
    @easy_sim.perform(@easy_puzzle)
    @hard_puzzle = SudokuPuzzle.new_puzzle(hard_constraints,'hard')
    @hard_sim = SudokuSolver.new
    @hard_sim.perform(@hard_puzzle)
  end
  after(:all) do
    # Cleanup the records created by the two simulations
    @easy_puzzle.destroy
    @hard_puzzle.destroy
    #Reset the environment variables
    ENV['SUDOKU_NUM_SWEEPS'] = @old_env
  end
  it "responds to perform" do
    is_expected.to respond_to(:perform)
  end
  it "responds to pretty" do
    is_expected.to respond_to(:pretty)
  end
  it "has the expected simulation results for the easy puzzle" do
    expect(@easy_puzzle.constraints).to eq(easy_constraints.join(""))
    expect(@easy_puzzle.solution).to eq(easy_solution)
    expect(@easy_puzzle.status).to match(/Solved/)
  end
  it "has the expected simulation results for the hard puzzle" do
    expect(@hard_puzzle.constraints).to eq(hard_constraints.join(""))
    expect(@hard_puzzle.solution).to eq(hard_solution)
    expect(@hard_puzzle.status).to match(/errors/)
  end
end
