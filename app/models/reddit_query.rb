class RedditQuery
  include HTTParty
  base_uri 'www.reddit.com'

  # Get new posts from a subreddit
  # useage
  # data = RedditQuery.new_posts('gaming')
  def self.new_posts(subreddit)
    response = self.get("/r/#{subreddit}/new.json")
    if response.code == 200
      return self.parse(response.body)
    else
      return nil
    end
  end

  # Search reddit for a post
  # Posts removed from subreddits down't show up on this search
  # useage
  # data = RedditQuery.search_one('MonsterHunter','5udxoh')
  def self.search_one(subreddit, full_id)
    response = self.get("/r/#{subreddit}/search.json", { query: { q: "fullname:#{full_id}" , limit: "1", t: "posts"} })
    if response.code == 200
      return self.parse(response.body)
    else
      return nil
    end
  end

  # Search reddit for many posts from a single subreddit
  # Assume we are given a set of fullnames
  # The search text should be of the form
  # fullname:<name1> OR fullname:<name2> OR ...
  # each search term represents 9+6+4 characters, or 19
  # search limit is 512 characters, so this limits us to
  # 26 simultaneous searches at most, but since we only get
  # 25 back by default, we will limit ourselves to that many
  # useage
  # data = RedditQuery.search_many('MonsterHunter',['5udxoh','5udxoh','5udxoh'])
  def self.search_many(subreddit, full_id_list)
    if full_id_list.count > 25
      # Only 25 results max allowed at a time
      return nil
    end
    query = "subreddit:#{subreddit} AND ("
    full_id_list.each do |fid|
      query << "fullname:#{fid} OR "
    end
    query = query[0..-5]
    query << ")"
    response = self.get("/search.json", { query: { q: query , limit: "25"} })
    if response.code == 200
      return self.parse(response.body)
    else
      return nil
    end
  end

  private
    def self.parse(msg)
      json_response = JSON.parse(msg)
      if json_response["data"] && json_response["data"]["children"]
        return json_response["data"]["children"]
      else
        return nil
      end
    end
end