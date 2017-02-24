require 'rails_helper'

gaming_json = JSON.parse(IO.read(Rails.root.join("spec", "models", "gaming_new.json"))).to_json

RSpec.describe RedditQuery, type: :model do
  it "responds to class method new_posts" do
    expect(RedditQuery).to respond_to(:new_posts)
    stub_request(:get, "http://www.reddit.com/r/gaming/new.json").
      to_return(:status => 200, :body => gaming_json, :headers => {})
    new_posts = RedditQuery.new_posts('gaming')
    expect(new_posts.size).to eq(100)
  end
  it "responds to class method search_one" do
    expect(RedditQuery).to respond_to(:search_one)
  end
  it "responds to class method search_many" do
    expect(RedditQuery).to respond_to(:search_many)
  end
end
