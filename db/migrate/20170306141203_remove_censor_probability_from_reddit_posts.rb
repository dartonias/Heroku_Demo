class RemoveCensorProbabilityFromRedditPosts < ActiveRecord::Migration
  def change
    remove_column :reddit_posts, :censor_probability, :float
  end
end
