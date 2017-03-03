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
    srs = RedditPost.distinct.pluck(:subreddit)
    srs.each do |sr|
      # Only keep the most recent 500 uncensored per subreddit that were uncensored after the check
      RedditPost.new_order.subreddit(sr).uncensored.matured.offset(500).destroy_all
      # Only keep the most recent 500 censored per subreddit, which must be after the check by definition
      RedditPost.new_order.subreddit(sr).censored.offset(500).destroy_all
    end
  end
end
