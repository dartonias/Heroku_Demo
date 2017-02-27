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

  desc "Update censored articles and delete old articles that have survived, as well as managing the database size"
  task update_censored: :environment do
    RedditPost.delete_old_batch
    RedditPost.order(created_utc: :desc).where(censored: true).offset(1000).destroy_all
  end
end
