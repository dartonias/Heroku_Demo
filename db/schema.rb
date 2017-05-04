# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20170504182126) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "reddit_posts", force: :cascade do |t|
    t.string   "reddit_id"
    t.string   "subreddit"
    t.integer  "created_utc"
    t.string   "title"
    t.string   "url"
    t.boolean  "censored",    default: false
    t.datetime "created_at",                  null: false
    t.datetime "updated_at",                  null: false
    t.boolean  "fresh",       default: true
  end

  create_table "remax_listings", force: :cascade do |t|
    t.string   "description"
    t.string   "name"
    t.string   "address"
    t.integer  "price"
    t.integer  "beds"
    t.integer  "baths"
    t.integer  "rooms"
    t.integer  "square"
    t.boolean  "extra_bed"
    t.boolean  "extra_bath"
    t.datetime "created_at",      null: false
    t.datetime "updated_at",      null: false
    t.string   "url"
    t.decimal  "longitude"
    t.decimal  "latitude"
    t.integer  "predicted_price"
  end

  create_table "sudoku_puzzles", force: :cascade do |t|
    t.string   "constraints"
    t.string   "solution"
    t.string   "status"
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
    t.string   "name"
  end

end
