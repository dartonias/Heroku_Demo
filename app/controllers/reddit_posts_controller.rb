class RedditPostsController < ApplicationController

  def index
    @censored_posts = RedditPost.where(censored: true)
    @watching_posts = RedditPost.where(censored: false)
  end
end
