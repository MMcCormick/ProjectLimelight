class TestJob
  include Resque::Plugins::UniqueJob
  @queue = :fast

  def self.perform()

    Post.all.each do |p|
      unless p.post_media_id
        p.destroy
      end
    end

  end
end