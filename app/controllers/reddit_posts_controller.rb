class RedditPostsController < ApplicationController

  def index
    limit = (params[:limit] || 25).to_i
    @censored_posts = RedditPost.search(params[:search]).regexp(params[:regexp]).where(censored: true).limit(limit)
    @watching_posts = RedditPost.search(params[:search]).regexp(params[:regexp]).where(censored: false).limit(limit)

    respond_to do |format|
      format.html
      format.json
    end
  end
end
