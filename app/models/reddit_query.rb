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