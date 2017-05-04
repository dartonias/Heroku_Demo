class AddExtrasToRemaxListings < ActiveRecord::Migration
  def change
    add_column :remax_listings, :longitude, :decimal
    add_column :remax_listings, :latitude, :decimal
    add_column :remax_listings, :predicted_price, :integer
  end
end
