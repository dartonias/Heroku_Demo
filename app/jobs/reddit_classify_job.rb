class RedditClassifyJob < ActiveJob::Base
  include SuckerPunch::Job

  def perform(*args)
    # Do something later
  end
end
