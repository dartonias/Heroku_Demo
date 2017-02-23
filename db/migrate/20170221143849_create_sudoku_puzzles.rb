class CreateSudokuPuzzles < ActiveRecord::Migration
  def change
    create_table :sudoku_puzzles do |t|
      t.string :constraints
      t.string :solution
      t.string :status

      t.timestamps null: false
    end
  end
end
