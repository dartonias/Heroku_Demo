require 'rails_helper'

post_data = {reddit_id: 'zzz123',
  subreddit: 'some_sub',
  created_utc: DateTime.now.to_i,
  title: 'Unoriginal title number 5',
  url: 'someurl.com/somearticle'}

post_array = (1..10).map do |i|
  this_hash = {}
  post_data.each do |key, val|
    if key == :reddit_id
      this_hash["id"] = i.to_s
    else
      this_hash[key.to_s] = val
    end
  end
  {"data" => this_hash}
end

# Sample returned from a search that should have no results
search_body = {"kind": "Listing", "data": {"facets": { }, "modhash": "sm3cj7m03p2eb142deaef41183c2ce127f1f46c8127373f283", "children": [ ], "after": nil, "before": nil } }.to_json

RSpec.describe RedditPost, type: :model do
  it "has appropriate fields" do
    post = RedditPost.create!(post_data)
    expect(post).to have_attributes(:reddit_id => post_data[:reddit_id])
    expect(post).to have_attributes(:subreddit => post_data[:subreddit])
    expect(post).to have_attributes(:created_utc => (a_value <= DateTime.now.to_i))
    expect(post).to have_attributes(:title => post_data[:title])
    expect(post).to have_attributes(:url => post_data[:url])
  end
  it "responds to class method add_to_watchlist" do
    expect(RedditPost).to respond_to(:add_to_watchlist)
    old_count = RedditPost.all.count
    RedditPost.add_to_watchlist(post_array)
    expect(RedditPost.all.count - old_count).to eq(post_array.size)
  end
  it "responds to class method search" do
    expect(RedditPost).to respond_to(:search)
    expect(RedditPost.search('test')).to be_a(RedditPost::ActiveRecord_Relation)
  end
  it "responds to class method regexp" do
    expect(RedditPost).to respond_to(:regexp)
    expect(RedditPost.search('test')).to be_a(RedditPost::ActiveRecord_Relation)
  end
  it "responds to class method delete_old" do
    expect(RedditPost).to respond_to(:delete_old)
    RedditPost.add_to_watchlist(post_array)
    stub_request(:get, /reddit.*search/).
      to_return(:status => 200, :body => search_body, :headers => {})
    # This return will assume that none of the search results came up, so they must have all been censored
    RedditPost.delete_old(-1.minutes)
    expect(RedditPost.count).to eq(post_array.size)
  end
  it "responds to class method delete_old_batch" do
    expect(RedditPost).to respond_to(:delete_old_batch)
    RedditPost.add_to_watchlist(post_array)
    # Force the deletion to check immediately
    ENV['OLD_TIME_HOURS'] = '-1'
    stub_request(:get, /reddit.*search/).
      to_return(:status => 200, :body => search_body, :headers => {})
    RedditPost.delete_old_batch
    expect(RedditPost.count).to eq(post_array.size)
  end
end