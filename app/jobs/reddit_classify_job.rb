class RedditClassifyJob < ActiveJob::Base
  include SuckerPunch::Job

  def perform(*args)
    # Do something later
  end

  def load_data
    @lsi = ClassifierReborn::LSI.new
    subreddits = RedditPost.pluck(:subreddit).uniq
    # Load all the currently mature data, by title
    subreddits.each do |sr|
      ar = RedditPost.subreddit(sr).matured.censored
      lsi.add_item ar, :censored, sr.to_sym { |x| ar.title }
      ar = RedditPost.subreddit(sr).matured.uncensored
      lsi.add_item ar, :uncensored, sr.to_sym { |x| ar.title }
    end
  end
end
