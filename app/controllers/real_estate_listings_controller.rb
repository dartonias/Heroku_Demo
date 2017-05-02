class RealEstateListingsController < ApplicationController
  
  def index
    @listings = RemaxListing.residential.limit(20)
  end
end
