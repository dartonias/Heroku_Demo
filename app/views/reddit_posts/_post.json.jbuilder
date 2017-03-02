json.subreddit post.subreddit
json.title post.title
if post.censor_probability
  json.censor_probability = post.censor_probability
end
json.reddit_link "https://www.reddit.com/r/#{post.subreddit}/comments/#{post.reddit_id}"
json.url post.url