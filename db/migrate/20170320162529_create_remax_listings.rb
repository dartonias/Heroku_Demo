class CreateRemaxListings < ActiveRecord::Migration
  def change
    create_table :remax_listings do |t|
      t.string :description
      t.string :name
      t.string :address
      t.integer :price
      t.integer :beds
      t.integer :baths
      t.integer :rooms
      t.integer :square
      t.boolean :extra_bed
      t.boolean :extra_bath

      t.timestamps null: false
    end
  end
end
