json.censored_posts do
  json.partial! partial: 'reddit_posts/post', collection: @censored_posts, as: :post
end
json.uncensored_posts do
  json.partial! partial: 'reddit_posts/post', collection: @uncensored_posts, as: :post
end
json.fresh_posts do
  json.partial! partial: 'reddit_posts/post', collection: @watching_posts, as: :post
end