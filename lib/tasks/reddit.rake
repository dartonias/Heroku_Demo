namespace :reddit do
  
  desc "Gets new entries from subreddits of interest"
  task get_new: :environment do
    subreddits = ENV['REDDIT_WATCH_SUBREDDITS'] || 'politics'
    subreddits = subreddits.split
    puts "Analyzing subreddits: #{subreddits}"
    subreddits.each do |sr|
      data = RedditQuery.new_posts(sr)
      if data
        puts "#{sr} gave #{data.size} posts"
        RedditPost.add_to_watchlist(data)
      end
    end
  end

  desc "Update censored articles and manage the database size to 2000 total entries older than ENV['OLD_TIME_HOURS']"
  task update_censored: :environment do
    RedditPost.check_censored_batch
    # Only keep the most recent 1000 uncensored that were uncensored after the check
    RedditPost.order(created_utc: :desc).where(censored: false).matured.offset(1000).destroy_all
    # Only keep the most recent 1000 censored, which must be after the check by definition
    RedditPost.order(created_utc: :desc).where(censored: true).offset(1000).destroy_all
  end
end
