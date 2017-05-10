json.listings do
  json.partial! partial: 'real_estate_listings/listing', collection: @listings, as: :listing
end