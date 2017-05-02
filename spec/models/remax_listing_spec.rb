require 'rails_helper'

page_1_html = IO.read(Rails.root.join("spec", "models", "page_1.html"))
page_2_html = IO.read(Rails.root.join("spec", "models", "page_2.html"))
empty = IO.read(Rails.root.join("spec", "models", "empty.html"))

RSpec.describe RemaxListing, type: :model do
  it "responds to add_new_listings and populates the database with results" do
    expect(RemaxListing).to respond_to(:add_new_listings)
    stub_request(:get, "http://www.remax.ca/on/kitchener-real-estate/").
    to_return(:status => 200, :body => page_1_html, :headers => {})
    stub_request(:get, "http://www.remax.ca/on/kitchener-real-estate/?page=2").
    to_return(:status => 200, :body => page_2_html, :headers => {})
    stub_request(:get, "http://www.remax.ca/on/kitchener-real-estate/?page=3").
    to_return(:status => 200, :body => empty, :headers => {})
    RemaxListing.add_new_listings
    expect(RemaxListing.all.count).to eq(40)
  end
end
