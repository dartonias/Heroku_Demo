class RedditClassifyJob < ActiveJob::Base
  include SuckerPunch::Job

  def perform(new_posts=nil)
    # Do something later
    load_data(new_posts)
  end

  private 
  def load_data(new_posts)
    @b = {}
    counts = {}
    cutoff = {}
    subreddits = RedditPost.pluck(:subreddit).uniq
    # Load all the currently mature data, by title
    # For better results, should take all mature data of a certain time window
    # since this gives us a relative fraction of censored to uncensored data
    subreddits.each do |sr|
      @b[sr] = Classifier::Bayes.new 'Censored', 'Uncensored'
      # Use 1/2 for training, 1/4 for cross-validation, 1/4 for tests
      counts[sr] = RedditPost.old_order.subreddit(sr).matured.censored.count/2
      ar = RedditPost.old_order.subreddit(sr).matured.censored.limit(counts[sr])
      # Want at least 10 examples to proceed
      if ar.count < 10
        return false
      end
      ar.each do |item|
        @b[sr].train_censored item.trim_title
      end

      ar = RedditPost.old_order.subreddit(sr).matured.uncensored.limit(counts[sr])
      # Want at least 10 examples to proceed
      if ar.count < 10
        return false
      end
      ar.each do |item|
        @b[sr].train_uncensored item.trim_title
      end
      # Cross validation
      cv_data = []
      cv_censored =   RedditPost.old_order.subreddit(sr).matured.  censored.offset(counts[sr]).limit(counts[sr]/2)
      cv_uncensored = RedditPost.old_order.subreddit(sr).matured.uncensored.offset(counts[sr]).limit(counts[sr]/2)
      cv_censored.each do |item|
        res = @b[sr].classifications item.trim_title
        res['is_cen'] = true
        cv_data << res
      end
      cv_uncensored.each do |item|
        res = @b[sr].classifications item.trim_title
        res['is_cen'] = false
        cv_data << res
      end
      cutoff[sr] = optimize_cutoff(cv_data)
    end
    if false
      new_posts.each do |item|
        res = @b[item.subreddit].classifications item.trim_title
        sum = res.values.reduce(0) {|sum, elem| sum + Math.exp(elem)}
        res.each do |key, val|
          res[key] = Math.exp(val)/sum
        end
        item.censor_probability = res['Censored']
        item.save
      end
    end
  end

  def optimize_cutoff(data)
    # Start with the assumption that there is no bias
    # We are comparing the log of the relative probabilities
    # so adding a constant is tantamount for weighting the 
    # different cases by a factor
    current = 0
    # Calculate the Cohen's_kappa, tp / (tp + fn + fp)
    # tp will be maximal for some value of 'current'
    # fp increase as 'current' increases
    # fn increase as 'current' decreases
    tp = 0
    fn = 0
    fp = 0
    tn = 0
    num_cen = 0
    total = 0
    data.each do |res|
      total += 1
      if (res['Censored'] + current) > res['Uncensored']
        if res['is_cen']
          tp += 1
          num_cen += 1
        else
          fp += 1
        end
      else
        if res['is_cen']
          fn += 1
          num_cen += 1
        else
          tn += 1
        end
      end
    end
    po = (tp + tn)/total.to_f
    pe = ((tp + fp)*(tp + fn) + (tn + fp)*(tn + fn))/(total.to_f ** 2)
    ck = (po - pe)/(1.0 - pe)
    puts "Cohen's kappa score is #{ck}"
    puts "tp: #{tp}, fp: #{fp}, tn: #{tn}, fn: #{fn}"
    puts "total: #{total}, num_cen: #{num_cen}"
    return current
  end
end
