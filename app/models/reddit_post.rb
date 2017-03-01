class RedditPost < ActiveRecord::Base
  scope :censored, -> { where(censored: true) }
  scope :uncensored, -> { where(censored: false) }
  scope :subreddit, ->(sr) { where(subreddit: sr) }

  # Look through the json data and
  # add any new entries to the database to watch
  # usage
  # RedditPost.add_to_watchlist(data)
  def self.add_to_watchlist(json_data)
    if !json_data.nil?
      json_data.each do |post|
        data = post_params(post)
        # Not found, so add it to the database
        if RedditPost.where({reddit_id: data["reddit_id"], subreddit: data["subreddit"]}).count < 1
          RedditPost.create(data)
        end
      end
    end
  end

  def self.search(query)
    if query and query.size > 0
      where("title LIKE ? OR title LIKE ? OR title LIKE ?", "%#{query}%", "%#{query.downcase}%", "%#{query.capitalize}%")
    else
      all
    end
  end

  def self.regexp(query)
    if query and query.size > 0
      where("title ~* ?", query)
    else
      all
    end
  end

  # Finds all posts that have survived at least old_limit time since creation
  # and marks them as censored or deletes them from the database.
  # Failed queries to reddit do not modify the database entries
  # useage
  # RedditPost.delete_old
  def self.delete_old(old_limit=5.minutes)
    # Get the seconds since the epoch to compare with created_utc
    oldest = (DateTime.now - old_limit).to_i
    # Only returns objects older than now - old_limit
    RedditPost.where(censored: false).where("created_utc < ?", oldest).each do |post|
      # Check if its censored, and if so flag as censored
      search_result = RedditQuery.search_one(post.subreddit, post.reddit_id)
      # If no response from the server, leave it for now
      if !search_result.nil?
        # A successful response returns an array of results
        # If zero results returned, it was censored, so we update and save
        if search_result.count < 1
          post.censored = true
          post.save
        else
          # If not censored, remove it from the db -- it survived the old_limit
          # but we're not interested in uncensored posts for now
          post.delete
        end
      end
    end
  end

  # Finds all posts that have survived at least old_limit time since creation
  # and marks them as censored or deletes them from the database.
  # Failed queries to reddit do not modify the database entries
  # This method uses batch query to reduce number of requests to reddit
  # useage
  # RedditPost.check_censored_batch
  def self.check_censored_batch
    # Get the seconds since the epoch to compare with created_utc
    old_limit = (ENV['OLD_TIME_HOURS'] || 24).to_i.hours
    batch_size = (ENV['REDDIT_BATCH_SIZE'] || 20).to_i
    debug = ENV['DEBUG_CHECK_CENSORED_BATCH']
    puts "Batch size: #{batch_size}" if debug
    oldest = (DateTime.now - old_limit).to_i
    # Array of distinct subreddits
    srs = RedditPost.distinct.pluck(:subreddit)
    srs.each do |sr|
      offset = 0
      num = RedditPost.order(:created_utc).where(censored: false, subreddit: sr).where("created_utc < ?", oldest).offset(offset).limit(batch_size).count
      puts "num: #{num}" if debug
      while num > 0 do
        ids = RedditPost.order(:created_utc).where(censored: false, subreddit: sr).where("created_utc < ?", oldest).offset(offset).limit(batch_size).pluck(:reddit_id)
        puts "sr: #{sr}, ids: #{ids}" if debug
        # Process here
        search_result = RedditQuery.search_many(sr,ids)
        if !search_result.nil?
          search_result.each do |res|
            data = post_params(res)
            puts "data: #{data}" if debug
            # We'll double check that it was in our initial list
            ids.delete(data["reddit_id"])
          end
          # Ones that were not found must have been censored
          ids.each do |cen_id|
            post = RedditPost.where(censored: false, subreddit: sr, reddit_id: cen_id).first
            post.censored = true
            post.save
          end
        else
          # If reddit gives us a bad URL code and hence nil for the search, we stop searching
          break
        end
        # End while logic
        offset += batch_size
        num = RedditPost.order(:created_utc).where(censored: false).where("created_utc < ?", oldest).offset(offset).limit(batch_size).count
      end
    end
  end

  private
    def self.post_params(prms)
      if prms["data"]
        r = prms["data"].slice("id","subreddit","created_utc","title","url")
        r["reddit_id"] = r.delete("id")
        return r
      else
        return nil
      end
    end
end
