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

RSpec.describe RedditPost, type: :model do
  it "has appropriate fields" do
    post = RedditPost.create!(post_data)
    expect(post).to have_attributes(:reddit_id => post_data[:reddit_id])
    expect(post).to have_attributes(:subreddit => post_data[:subreddit])
    expect(post).to have_attributes(:created_utc => (a_value <= DateTime.now.to_i))
    expect(post).to have_attributes(:title => post_data[:title])
    expect(post).to have_attributes(:url => post_data[:url])
  end
  it "responds to class method add_to_watchlist and adds posts to database" do
    expect(RedditPost).to respond_to(:add_to_watchlist)
    old_count = RedditPost.all.count
    # Mocking RedditClassifyJob.new.perform(new_posts)
    allow_any_instance_of(RedditClassifyJob).to receive(:perform)
    RedditPost.add_to_watchlist(post_array)
    expect(RedditPost.all.count - old_count).to eq(post_array.size)
  end
  it "responds to class method search and returns an ActiveRecord_Relation" do
    expect(RedditPost).to respond_to(:search)
    expect(RedditPost.search('test')).to be_a(RedditPost::ActiveRecord_Relation)
  end
  it "responds to class method regexp and returns an ActiveRecord_Relation" do
    expect(RedditPost).to respond_to(:regexp)
    expect(RedditPost.search('test')).to be_a(RedditPost::ActiveRecord_Relation)
  end
  it "responds to class method delete_old that removes entries from the database" do
    expect(RedditPost).to respond_to(:delete_old)
    # Mocking RedditClassifyJob.new.perform(new_posts)
    allow_any_instance_of(RedditClassifyJob).to receive(:perform)
    RedditPost.add_to_watchlist(post_array)
    # This return will assume that the first 5 of the search results came up, so they must have all been censored
    count = 0
    allow(RedditQuery).to receive(:search_one) do |subreddit, reddit_id|
      count += 1
      if count <= 5
        post_array.sample(1)
      else
        []
      end
    end
    RedditPost.delete_old(-1.minutes)
    expect(RedditPost.count).to eq(post_array.size - 5)
  end
  it "responds to class method check_censored_batch which can delete many entries from the database" do
    expect(RedditPost).to respond_to(:check_censored_batch)
    # Mocking RedditClassifyJob.new.perform(new_posts)
    allow_any_instance_of(RedditClassifyJob).to receive(:perform)
    RedditPost.add_to_watchlist(post_array)
    # This return will assume that 5 of the search results came up, so those 5 must have been censored
    ENV['OLD_TIME_HOURS'] = '-1'
    allow(RedditQuery).to receive(:search_many) do |sr, id|
      post_array.sample(5)
    end
    RedditPost.check_censored_batch
    expect(RedditPost.censored.count).to eq(post_array.size - 5)
  end
end