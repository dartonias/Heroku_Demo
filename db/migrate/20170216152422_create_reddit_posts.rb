class CreateRedditPosts < ActiveRecord::Migration
  def change
    create_table :reddit_posts do |t|
      t.string :reddit_id
      t.string :subreddit
      t.integer :created_utc
      t.string :title
      t.string :url
      t.boolean :censored, :default => false

      t.timestamps null: false
    end
  end
end
