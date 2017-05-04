namespace :remax do

  desc "Gets new entries from the ReMax backend and then cleans up the entries in the database"
  task fetch_new: :environment do
    RemaxListing.add_new_listings
    RemaxListing.cleanup
    RemaxListing.new_order.offset(4000).destroy_all
  end
  
end