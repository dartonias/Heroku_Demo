class AddFreshToRedditPosts < ActiveRecord::Migration
  def change
    add_column :reddit_posts, :fresh, :boolean, :default => true
  end
end
