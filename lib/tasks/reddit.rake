namespace :reddit do
  
  desc "Gets new entries from subreddits of interest"
  task get_new: :environment do
    subreddits = ['politics']
    subreddits.each do |sr|
      data = RedditQuery.new_posts(sr)
      RedditPost.add_to_watchlist(data)
    end
  end

  desc "Update censored articles and delete old articles that have survived, as well as managing the database size"
  task update_censored: :environment do
    RedditPost.delete_old_batch
    RedditPost.order(created_utc: :desc).where(censored: true).offset(1000).destroy_all
  end
end
