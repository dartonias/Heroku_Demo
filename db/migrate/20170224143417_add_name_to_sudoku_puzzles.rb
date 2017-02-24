class AddNameToSudokuPuzzles < ActiveRecord::Migration
  def change
    add_column :sudoku_puzzles, :name, :string
  end
end
