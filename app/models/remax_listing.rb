class RemaxListing < ActiveRecord::Base
  scope :new_order, -> { order(:created_at => :desc) }
  
  RESIDENTIAL_TYPES = ["House", "Detached", "Att/Row/Twnhouse", "Duplex", "Apartment", "Single Family", "Townhouses", "Multi-Family", "Triplex", "Condominiums", "Condo Townhouse", "Condo Apt"]
  
  def self.residential
    # Hand pruned list of residential offerings
    where(description: RESIDENTIAL_TYPES)
  end

  def self.has_prediction
    where.not('price_prediction' => nil)
  end
  
  def self.add_new_listings
    listings = RemaxQuery.results
    listings.each do |item|
      # Insert each element into the database if it is not currently present
      # Similarity between listings is done by the "url" field being an exact match
      if RemaxListing.where({url: item["url"]}).count > 0
        # do nothing
      else
        RemaxListing.create(item)
      end
    end
  end
  
  def self.cleanup
    where.not(description: RESIDENTIAL_TYPES).delete_all
  end
  
  def self.search(query)
    # Should check name, address, and description
    if query and query.size > 0
      where("name LIKE ? OR name LIKE ? OR name LIKE ? OR address LIKE ? OR address LIKE ? OR address LIKE ? OR description LIKE ? OR description LIKE ? OR description LIKE ?",
      "%#{query}%", "%#{query.downcase}%", "%#{query.capitalize}%",
      "%#{query}%", "%#{query.downcase}%", "%#{query.capitalize}%",
      "%#{query}%", "%#{query.downcase}%", "%#{query.capitalize}%")
    else
      all
    end
  end

  def self.regexp(query)
    if query and query.size > 0
      where("name ~* ? OR address ~* ? OR description ~* ?", query, query, query)
    else
      all
    end
  end

  def self.gt(val)
    if val and val.to_i > 0
      where("price > ?", val.to_i)
    else
      all
    end
  end

  def self.lt(val)
    if val and val.to_i > 0
      where("price < ?", val.to_i)
    else
      all
    end
  end
end