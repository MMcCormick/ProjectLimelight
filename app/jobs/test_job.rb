class TestJob
  include Resque::Plugins::UniqueJob
  @queue = :fast

  def self.perform()
    posts = PostMedia.where("shares.mediums.id" => {"$exists" => true})
    posts.each do |p|
      begin
        tweet = Twitter.status(p.shares[0]['mediums'][0]['id'].to_i)
        p.shares[0]['mediums'][0]['id'] = tweet.id.to_i
        p.shares[0].created_at = tweet.created_at
        p.save
      rescue => e
        p.delete_share(p.shares[0].user_id)
        if p.status == 'pending' && p.shares.length == 0
          p.destroy
        else
          p.save
        end
      end
    end
  end
end