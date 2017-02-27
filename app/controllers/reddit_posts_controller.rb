class RedditPostsController < ApplicationController

  def index
    subreddits = RedditPost.pluck(:subreddit).uniq
    limit = (params[:limit] || 25).to_i
    @censored_posts = []
    @watching_posts = []
    sr_count = 0
    subreddits.each do |sr|
      sr_count += 1
      if sr_count < subreddits.size
        censored_lim = limit/subreddits.size
        watching_lim = limit/subreddits.size
      else
        censored_lim = limit - @censored_posts.size
        watching_lim = limit - @watching_posts.size
      end
      @censored_posts.concat(RedditPost.search(params[:search]).regexp(params[:regexp]).where(censored: true).where(subreddit: sr).limit(censored_lim))
      @watching_posts.concat(RedditPost.search(params[:search]).regexp(params[:regexp]).where(censored: false).where(subreddit: sr).limit(watching_lim))
    end
    respond_to do |format|
      format.html
      format.json
    end
  end
end
