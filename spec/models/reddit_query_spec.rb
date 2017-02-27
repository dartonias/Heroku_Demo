require 'rails_helper'

gaming_hash = JSON.parse(IO.read(Rails.root.join("spec", "models", "gaming_new.json")))
gaming_json = gaming_hash.to_json
search_one_hash = JSON.parse(IO.read(Rails.root.join("spec", "models", "search_one.json")))
search_one_json = search_one_hash.to_json
search_many_hash = JSON.parse(IO.read(Rails.root.join("spec", "models", "search_many.json")))
search_many_json = search_many_hash.to_json
fields = ["id","subreddit","created_utc","title","url"]
canada_ids = ["5wh64a", "5wh4u3", "5wh40z", "5wh1b3", "5wh0fh"]

RSpec.describe RedditQuery, type: :model do
  it "responds to class method new_posts, that converts incoming json to expected format" do
    expect(RedditQuery).to respond_to(:new_posts)
    stub_request(:get, "http://www.reddit.com/r/gaming/new.json").
      to_return(:status => 200, :body => gaming_json, :headers => {})
    new_posts = RedditQuery.new_posts('gaming')
    expect(new_posts.size).to eq(gaming_hash['data']['children'].size)
  end
  it "responds to class method search_one, that converts incoming json to expected format" do
    expect(RedditQuery).to respond_to(:search_one)
    stub_request(:get, "http://www.reddit.com/r/gaming/search.json?limit=1&q=fullname:5e6j8h&t=posts").
      to_return(:status => 200, :body => search_one_json, :headers => {})
    post = RedditQuery.search_one('gaming','5e6j8h')
    expect(post.size).to eq(1)
    expect(post[0]["data"]).not_to be_nil
    fields.each do |f|
      expect(post[0]["data"][f]).to eq(search_one_hash['data']['children'][0]['data'][f])
    end
  end
  it "responds to class method search_many, that converts incoming json to expected format" do
    expect(RedditQuery).to respond_to(:search_many)
    stub_request(:get, "http://www.reddit.com/search.json?limit=25&q=subreddit:canada%20AND%20(fullname:5wh64a%20OR%20fullname:5wh4u3%20OR%20fullname:5wh40z%20OR%20fullname:5wh1b3%20OR%20fullname:5wh0fh)").
      to_return(:status => 200, :body => search_many_json, :headers => {})
    posts = RedditQuery.search_many('canada',canada_ids)
    expect(posts.size).to eq(search_many_hash['data']['children'].size)
    (0..posts.size-1).each do |i|
      fields.each do |f|
        expect(posts[i]['data'][f]).to eq(search_many_hash['data']['children'][i]['data'][f])
      end
    end
  end
end
