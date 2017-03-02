class RedditClassifyJob < ActiveJob::Base
  include SuckerPunch::Job

  def perform(new_posts)
    # Do something later
    load_data(new_posts)
  end

  private 
  def load_data(new_posts)
    @b = Classifier::Bayes.new 'Censored', 'Uncensored'
    subreddits = RedditPost.pluck(:subreddit).uniq
    # Load all the currently mature data, by title
    # For better results, should take all mature data of a certain time window
    # since this gives us a relative fraction of censored to uncensored data
    subreddits.each do |sr|
      ar = RedditPost.subreddit(sr).matured.censored
      # Want at least 10 examples to proceed
      if ar.count < 10
        return false
      end
      ar.each do |item|
        @b.train_censored item.trim_title
      end
      ar = RedditPost.subreddit(sr).matured.uncensored
      # Want at least 10 examples to proceed
      if ar.count < 10
        return false
      end
      ar.each do |item|
        @b.train_uncensored item.trim_title
      end
    end
    new_posts.each do |item|
      res = @b.classifications item.trim_title
      sum = res.values.reduce(0) {|sum, elem| sum + Math.exp(elem)}
      res.each do |key, val|
        res[key] = Math.exp(val)/sum
      end
      item.censor_probability = res['Censored']
      item.save
    end
  end
end
