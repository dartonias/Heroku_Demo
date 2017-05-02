class AddUrlToRemaxListings < ActiveRecord::Migration
  def change
    add_column :remax_listings, :url, :string
  end
end
