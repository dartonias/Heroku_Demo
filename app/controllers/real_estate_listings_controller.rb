class RealEstateListingsController < ApplicationController
  
  def index
    if params[:regexp] and params[:regexp].size > 0
      params[:search] = ''
    end
    if not params[:limit]
      params[:limit] = 20
    end

    @listings = RemaxListing.residential.search(params[:search]).regexp(params[:regexp]).gt(params[:minprice]).lt(params[:maxprice]).limit(params[:limit])
  end
end
