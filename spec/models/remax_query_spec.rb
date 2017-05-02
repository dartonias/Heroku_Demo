require 'rails_helper'

#page_1_html = IO.read(Rails.root.join("spec", "models", "page_1.html"))
#page_2_html = IO.read(Rails.root.join("spec", "models", "page_2.html"))

RSpec.describe RemaxQuery, type: :model do
  it "responds to class method results and parses data from returned call" do
    expect(RemaxQuery).to respond_to(:results)
    res = RemaxQuery.results
    expect(res.size).to eq(40)
    one_result = res.sample
    expect(one_result).to include("description")
    expect(one_result).to include("name")
    expect(one_result).to include("address")
    expect(one_result).to include("price")
    expect(one_result).to include("beds")
    expect(one_result).to include("baths")
    expect(one_result).to include("rooms")
    expect(one_result).to include("square")
  end
end
