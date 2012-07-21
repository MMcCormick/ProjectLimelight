class RecalculatePostScores
  include Resque::Plugins::UniqueJob

  @queue = :slow

  def self.perform()
    PostMedia.all.each do |p|
      p.calculate_score
      p.save
    end
  end
end