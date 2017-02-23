namespace :sudoku do

  desc "Cleanup older entries in the database of sudoku puzzles"
  task cleanup: :environment do
    SudokuPuzzle.order(updated_at: :desc).offset(1000).destroy_all
  end
end
