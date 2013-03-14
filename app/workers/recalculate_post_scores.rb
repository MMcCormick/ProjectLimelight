class RecalculatePostScores
  include Sidekiq::Worker
  sidekiq_options :queue => :slow_limelight, :unique => true

  def perform()
    PostMedia.all.each do |p|
      p.calculate_score
      p.save
    end
  end
end