require 'rails_helper'

post_data = {reddit_id: 'zzz123',
  subreddit: 'some_sub',
  created_utc: DateTime.now.to_i,
  title: 'Unoriginal title number 5',
  url: 'someurl.com/somearticle'}

# Should be even for simplicity
post_size = 20
post_array = []
(1..post_size).each do |i|
  elem = {}
  post_data.each do |key,val|
    if key == 'reddit_id'
      elem[key] = "zzz#{i}"
    else
      elem[key] = val
    end
  end
  if i <= post_size/2
    elem[:subreddit] = 'sub1'
  else
    elem[:subreddit] = 'sub2'
  end
  if i % 2 == 0
    elem[:censored] = true
  end
  if i == 5
    elem[:title] = 'A unique title'
  end
  post_array << elem
end


RSpec.describe RedditPostsController, type: :controller do
  it "responds to index" do
    is_expected.to respond_to(:index)
  end
  it "defines @censored_posts and @watching_posts" do
    get :index
    expect(assigns(:censored_posts)).to eq([])
    expect(assigns(:watching_posts)).to eq([])
  end
  it "defines the expected @censored_posts and @watching_posts given arguments" do
    RedditPost.create!(post_array)
    expect(RedditPost.all.count).to eq(post_array.size)
    get :index
    expect(assigns(:censored_posts).size).to eq(post_array.size/2)
    expect(assigns(:watching_posts).size).to eq(post_array.size/2)
    assigns(:censored_posts).each do |post|
      expect(post[:censored]).to be true
    end
    assigns(:watching_posts).each do |post|
      expect(post[:censored]).to be false
    end
    num_lim = 6
    get :index, {:limit => num_lim}
    expect(assigns(:censored_posts).size).to eq(num_lim)
    expect(assigns(:watching_posts).size).to eq(num_lim)
    get :index, {:search => 'unique'}
    expect(assigns(:censored_posts).size).to eq(0)
    expect(assigns(:watching_posts).size).to eq(1)
    get :index, {:regexp => '^Un'}
    expect(assigns(:censored_posts).size).to eq(post_array.size/2)
    expect(assigns(:watching_posts).size).to eq(post_array.size/2 - 1)
    get :index, {:subreddit => '1'}
    expect(assigns(:censored_posts).size).to eq(post_array.size/4)
    expect(assigns(:watching_posts).size).to eq(post_array.size/4)
  end
end
