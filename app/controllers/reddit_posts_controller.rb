class RedditPostsController < ApplicationController

  def index
    subreddits = RedditPost.pluck(:subreddit).uniq
    limit = (params[:limit] || 25).to_i
    @censored_posts = []
    @uncensored_posts = []
    @watching_posts = []
    if params[:regexp] and params[:regexp].size > 0
      params[:search] = ''
    end
    sr_count = 0
    subreddits.each do |sr|
      limit_subs = false
      if params[:subreddit] && params[:subreddit].size > 0
        limit_subs = true
        next unless /#{params[:subreddit]}/ === sr
      end
      sr_count += 1
      if sr_count < subreddits.size && !limit_subs
        censored_lim = [limit/subreddits.size, 1].max
        uncensored_lim = [limit/subreddits.size, 1].max
        watching_lim = [limit/subreddits.size, 1].max
      else
        censored_lim = [limit - @censored_posts.size, 1].max
        uncensored_lim = [limit - @censored_posts.size, 1].max
        watching_lim = [limit - @watching_posts.size, 1].max
      end
      @censored_posts.concat(RedditPost.search(params[:search]).regexp(params[:regexp]).censored.only_matured.subreddit(sr).new_order.limit(censored_lim))
      @uncensored_posts.concat(RedditPost.search(params[:search]).regexp(params[:regexp]).uncensored.only_matured.subreddit(sr).new_order.limit(censored_lim))
      @watching_posts.concat(RedditPost.search(params[:search]).regexp(params[:regexp]).only_fresh.subreddit(sr).new_order.limit(watching_lim))
    end
    respond_to do |format|
      format.html
      format.json
    end
  end
end
