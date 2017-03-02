class RedditClassifyJob < ActiveJob::Base
  include SuckerPunch::Job

  def perform(*args)
    # Do something later
    load_data
  end

  private 
  def load_data
    @lsi = ClassifierReborn::LSI.new
    subreddits = RedditPost.pluck(:subreddit).uniq
    # Load all the currently mature data, by title
    subreddits.each do |sr|
      ar = RedditPost.subreddit(sr).matured.censored.limit(10)
      lsi.add_item ar, :censored, sr.to_sym { |x| ar.title }
      ar = RedditPost.subreddit(sr).matured.uncensored.limit(10)
      lsi.add_item ar, :uncensored, sr.to_sym { |x| ar.title }
    end
    test_cen = RedditPost.matured.censored.offset(10).limit(10)
    test_uncen = RedditPost.matured.uncensored.offset(10).limit(10)
    test_cen.each do |post|
      puts lsi.classify_with_score post.title
    end
    test_uncen.each do |post|
      puts lsi.classify_with_score post.title
    end
  end
end
