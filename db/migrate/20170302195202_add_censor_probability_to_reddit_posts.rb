class AddCensorProbabilityToRedditPosts < ActiveRecord::Migration
  def change
    add_column :reddit_posts, :censor_probability, :float
  end
end
