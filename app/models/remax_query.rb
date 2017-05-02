class RemaxQuery
  include HTTParty
  base_uri 'www.remax.ca'
  
  def self.results
    # Backend search engine with default arguments when visiting the main page
    # Allows for getting all the results in a single page, which is what we do here
    searches = ["https://www.remax.ca/listinglistsearch/listingslist/?type=forSale&province=ON&cityName=KITCHENER&listingPageSize=500",
      "https://www.remax.ca/listinglistsearch/listingslist/?type=forSale&province=ON&cityName=WATERLOO&listingPageSize=10"]
    results_vec = []
    fields = ["propertyDescription",
      "propertyName",
      "propertyAddress",
      "propertyPrice",
      "propertyBeds",
      "propertyBaths",
      "propertyRooms",
      "propertySquare"]
    searches.each do |s|
      response = self.get(s)
      if response.code == 200
        doc = Nokogiri::HTML(response.body)
        entries = doc.css('div.leftColumn')
        entries.each do |e|
          data = {}
          fields.each do |f|
            data[f[8..-1].downcase] = e.css("li.#{f}").text.strip
          end
          data["url"] = e.css("a").first["href"]
          # Assume no decimal and cents are given in housing prices
          data["price"] = data["price"][1..-1].gsub(/\D/,'').to_i
          data["extra_bed"] = data["beds"].include?('+ 1')
          data["beds"] = data["beds"].to_i
          data["extra_bath"] = data["baths"].include?('+ 1')
          data["baths"] = data["baths"].to_i
          data["rooms"] = data["rooms"].to_i
          data["square"] = data["square"].to_i
          results_vec << data
        end
      end
    end
    return results_vec 
  end
end